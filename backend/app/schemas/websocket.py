"""
WebSocket Message Schemas - Message types for signaling protocol
Tüm WebSocket mesajlarının JSON formatı burada tanımlı.
"""
from pydantic import BaseModel
from typing import Optional, Any, Dict


# === Client → Server Mesajları ===

class JoinQueueMessage(BaseModel):
    """Eşleşme kuyruğuna katıl"""
    type: str = "JOIN_QUEUE"


class LeaveQueueMessage(BaseModel):
    """Kuyruktan ayrıl"""
    type: str = "LEAVE_QUEUE"


class NextMessage(BaseModel):
    """Sonraki eşe geç"""
    type: str = "NEXT"


class OfferMessage(BaseModel):
    """WebRTC SDP offer gönder"""
    type: str = "OFFER"
    connection_id: str
    sdp: str


class AnswerMessage(BaseModel):
    """WebRTC SDP answer gönder"""
    type: str = "ANSWER"
    connection_id: str
    sdp: str


class IceCandidateMessage(BaseModel):
    """WebRTC ICE candidate gönder"""
    type: str = "ICE_CANDIDATE"
    connection_id: str
    candidate: Dict[str, Any]


class ChatMessageSend(BaseModel):
    """Metin mesajı gönder"""
    type: str = "CHAT_MESSAGE"
    connection_id: str
    text: str


# === Server → Client Mesajları ===

class MatchFoundMessage(BaseModel):
    """Eş bulundu bildirimi"""
    type: str = "MATCH_FOUND"
    connection_id: str
    is_initiator: bool


class MatchEndedMessage(BaseModel):
    """Eşleşme sona erdi"""
    type: str = "MATCH_ENDED"
    reason: str  # NEXTED, DISCONNECTED, BANNED


class QueuePositionMessage(BaseModel):
    """Kuyruk pozisyonu"""
    type: str = "QUEUE_POSITION"
    position: int
    estimated_wait_sec: Optional[int] = None


class PartnerOfferMessage(BaseModel):
    """Eşten gelen offer"""
    type: str = "OFFER"
    sdp: str


class PartnerAnswerMessage(BaseModel):
    """Eşten gelen answer"""
    type: str = "ANSWER"
    sdp: str


class PartnerIceCandidateMessage(BaseModel):
    """Eşten gelen ICE candidate"""
    type: str = "ICE_CANDIDATE"
    candidate: Dict[str, Any]


class PartnerChatMessage(BaseModel):
    """Eşten gelen mesaj"""
    type: str = "CHAT_MESSAGE"
    text: str


class BannedMessage(BaseModel):
    """Yasaklandınız bildirimi"""
    type: str = "BANNED"
    reason: str
    expires_at: Optional[str] = None


class ErrorMessage(BaseModel):
    """Hata mesajı"""
    type: str = "ERROR"
    code: str
    message: str


class OnlineCountMessage(BaseModel):
    """Çevrimiçi kullanıcı sayısı"""
    type: str = "ONLINE_COUNT"
    count: int
