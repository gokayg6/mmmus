"""
Matchmaking Service - Queue management and pairing logic
Bu servis in-memory olarak çalışır. Horizontal scaling için Redis kullanılmalı.

AKIŞ:
1. Kullanıcı JOIN_QUEUE gönderir
2. Kuyrukta başka biri varsa eşleştirilir, yoksa kuyruğa eklenir
3. Eşleşme olduğunda her iki tarafa MATCH_FOUND gönderilir
4. isInitiator=true olan taraf WebRTC offer oluşturur
5. Diğer taraf answer ile yanıtlar
6. ICE candidate'lar karşılıklı iletilir
7. NEXT veya disconnect olduğunda bağlantı sonlandırılır
"""
import asyncio
from datetime import datetime
from typing import Dict, Optional, Tuple, Any
from uuid import UUID, uuid4
from dataclasses import dataclass, field


@dataclass
class QueuedUser:
    """Kuyrukta bekleyen kullanıcı"""
    session_id: UUID
    session_token: str
    gender: str = "UNSPECIFIED"
    preferred_gender: Optional[str] = None
    joined_at: datetime = field(default_factory=datetime.utcnow)
    websocket: Any = None


@dataclass 
class ActiveConnection:
    """Aktif video sohbet bağlantısı"""
    connection_id: UUID
    session_a_id: UUID
    session_b_id: UUID
    started_at: datetime = field(default_factory=datetime.utcnow)


class MatchmakingService:
    """
    In-memory matchmaking servisi.
    Production'da Redis Pub/Sub ile değiştirilmeli.
    """
    
    def __init__(self):
        # Kuyruk: session_id -> QueuedUser
        self._queue: Dict[UUID, QueuedUser] = {}
        
        # Aktif bağlantılar: connection_id -> ActiveConnection
        self._connections: Dict[UUID, ActiveConnection] = {}
        
        # Session -> Connection mapping: session_id -> connection_id
        self._session_connections: Dict[UUID, UUID] = {}
        
        # Session -> WebSocket mapping: session_id -> websocket
        self._session_websockets: Dict[UUID, Any] = {}
        
        # Thread-safe için lock
        self._lock = asyncio.Lock()
    
    @property
    def online_count(self) -> int:
        """Toplam online kullanıcı (kuyruk + aktif bağlantılardakiler)"""
        # Kuyruktakiler + Aktif bağlantılardaki tüm session'lar
        unique_sessions = set()
        # Kuyruktakiler
        unique_sessions.update(self._queue.keys())
        # Aktif bağlantılardakiler
        for connection in self._connections.values():
            unique_sessions.add(connection.session_a_id)
            unique_sessions.add(connection.session_b_id)
        return len(unique_sessions)
    
    @property
    def queue_size(self) -> int:
        """Kuyrukta bekleyenler"""
        return len(self._queue)
    
    @property
    def active_connections_count(self) -> int:
        """Aktif bağlantı sayısı"""
        return len(self._connections)
    
    async def register_websocket(self, session_id: UUID, websocket) -> None:
        """WebSocket bağlantısını kaydet"""
        async with self._lock:
            self._session_websockets[session_id] = websocket
    
    async def unregister_websocket(self, session_id: UUID) -> None:
        """WebSocket bağlantısını kaldır"""
        async with self._lock:
            self._session_websockets.pop(session_id, None)
    
    def get_websocket(self, session_id: UUID):
        """Session için WebSocket al"""
        return self._session_websockets.get(session_id)
    
    def get_all_websockets(self):
        """Tüm WebSocket'leri al (broadcast için)"""
        return dict(self._session_websockets)  # Return copy
    
    async def join_queue(self, user: QueuedUser) -> Optional[Tuple[UUID, UUID, bool]]:
        """
        Kuyruğa katıl ve eşleşme dene.
        Eşleşme olursa: (connection_id, partner_session_id, is_initiator) döner
        Kuyruğa eklendiyse: None döner
        """
        async with self._lock:
            # Zaten kuyrukta veya bağlantıda mı?
            if user.session_id in self._queue:
                return None
            if user.session_id in self._session_connections:
                return None
            
            # Eşleşme ara
            match = self._find_match(user)
            
            if match:
                # Bağlantı oluştur
                connection_id = uuid4()
                connection = ActiveConnection(
                    connection_id=connection_id,
                    session_a_id=user.session_id,
                    session_b_id=match.session_id
                )
                
                # Eşleşen kullanıcıyı kuyruktan çıkar
                del self._queue[match.session_id]
                
                # Bağlantıyı kaydet
                self._connections[connection_id] = connection
                self._session_connections[user.session_id] = connection_id
                self._session_connections[match.session_id] = connection_id
                
                # Yeni gelen initiator olsun (offer oluşturacak)
                return (connection_id, match.session_id, True)
            else:
                # Kuyruğa ekle
                self._queue[user.session_id] = user
                return None
    
    def _find_match(self, user: QueuedUser) -> Optional[QueuedUser]:
        """Kuyruktan eşleşecek birini bul (FIFO)"""
        for session_id, queued_user in self._queue.items():
            if session_id != user.session_id:
                # Basit FIFO eşleştirme
                # İleride: cinsiyet filtresi, ülke filtresi eklenebilir
                return queued_user
        return None
    
    async def leave_queue(self, session_id: UUID) -> bool:
        """Kuyruktan ayrıl"""
        async with self._lock:
            if session_id in self._queue:
                del self._queue[session_id]
                return True
            return False
    
    async def end_connection(self, session_id: UUID, reason: str = "NEXTED") -> Optional[UUID]:
        """
        Mevcut bağlantıyı sonlandır.
        Partner'ın session_id'sini döner (varsa).
        """
        async with self._lock:
            connection_id = self._session_connections.get(session_id)
            if not connection_id:
                return None
            
            connection = self._connections.get(connection_id)
            if not connection:
                return None
            
            # Partner'ı bul
            if connection.session_a_id == session_id:
                partner_id = connection.session_b_id
            else:
                partner_id = connection.session_a_id
            
            # Temizlik
            del self._connections[connection_id]
            self._session_connections.pop(session_id, None)
            self._session_connections.pop(partner_id, None)
            
            return partner_id
    
    async def get_connection(self, session_id: UUID) -> Optional[ActiveConnection]:
        """Session için aktif bağlantıyı al"""
        connection_id = self._session_connections.get(session_id)
        if connection_id:
            return self._connections.get(connection_id)
        return None
    
    async def get_partner_session_id(self, session_id: UUID) -> Optional[UUID]:
        """Partner'ın session_id'sini al"""
        connection = await self.get_connection(session_id)
        if connection:
            if connection.session_a_id == session_id:
                return connection.session_b_id
            else:
                return connection.session_a_id
        return None
    
    async def get_queue_position(self, session_id: UUID) -> Optional[int]:
        """Kuyruktaki pozisyonu al (1'den başlar)"""
        position = 1
        for sid in self._queue.keys():
            if sid == session_id:
                return position
            position += 1
        return None
    
    async def cleanup_session(self, session_id: UUID) -> Optional[UUID]:
        """
        Disconnect olan session için temizlik yap.
        Partner varsa partner_id döner.
        """
        # Kuyruktan çıkar
        await self.leave_queue(session_id)
        
        # Bağlantıyı sonlandır
        partner_id = await self.end_connection(session_id, "DISCONNECTED")
        
        # WebSocket'i kaldır
        await self.unregister_websocket(session_id)
        
        return partner_id


# Global singleton instance
_matchmaking_service = None


def get_matchmaking_service() -> MatchmakingService:
    """Matchmaking servis instance'ını al"""
    global _matchmaking_service
    if _matchmaking_service is None:
        _matchmaking_service = MatchmakingService()
    return _matchmaking_service
