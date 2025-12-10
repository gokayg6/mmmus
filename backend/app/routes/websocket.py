"""
WebSocket Routes - Signaling and Matchmaking
The core of the real-time functionality.
"""
import json
import asyncio
from uuid import UUID
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends
from sqlalchemy.orm import Session

from app.database import get_session_local
from app.services.matchmaking import get_matchmaking_service, QueuedUser
from app.models.user_session import UserSession
from app.models.connection import EndedReason

router = APIRouter()
mm_service = get_matchmaking_service()


@router.websocket("/ws/signaling")
async def websocket_endpoint(websocket: WebSocket, session_token: str):
    """
    WebSocket endpoint for signaling and matchmaking.
    Requires a valid session_token as query parameter.
    """
    # 1. Connection Accept & Validation
    await websocket.accept()
    
    # Get sessionmaker and create a session instance
    SessionLocal = get_session_local()
    db = SessionLocal()
    try:
        session = db.query(UserSession).filter(UserSession.session_token == session_token).first()
        
        if not session or not session.is_active:
            await websocket.close(code=4001, reason="Invalid session")
            db.close()
            return
            
        session_id = session.id
        gender = session.gender.value if session.gender else "UNSPECIFIED"
        
    finally:
        db.close()
        
    # 2. Register WebSocket
    await mm_service.register_websocket(session_id, websocket)
    
    try:
        # 3. Message Loop
        while True:
            data = await websocket.receive_text()
            message = json.loads(data)
            msg_type = message.get("type")
            
            if msg_type == "JOIN_QUEUE":
                await handle_join_queue(session_id, session_token, gender, websocket)
                
            elif msg_type == "LEAVE_QUEUE":
                await mm_service.leave_queue(session_id)
                
            elif msg_type == "NEXT":
                await handle_next(session_id)
                
            elif msg_type == "OFFER":
                await forward_signal(session_id, message)
                
            elif msg_type == "ANSWER":
                await forward_signal(session_id, message)
                
            elif msg_type == "ICE_CANDIDATE":
                await forward_signal(session_id, message)
                
            elif msg_type == "CHAT_MESSAGE":
                await forward_chat(session_id, message)
                
    except WebSocketDisconnect:
        # Handle disconnect (automatic leave queue/end match)
        partner_id = await mm_service.cleanup_session(session_id)
        if partner_id:
            await notify_partner_end(partner_id, "DISCONNECTED")
            
    except Exception as e:
        print(f"WebSocket Error for {session_id}: {e}")
        await mm_service.cleanup_session(session_id)


async def handle_join_queue(session_id: UUID, token: str, gender: str, ws: WebSocket):
    """Kuyruğa katıl ve eşleşme varsa başlat"""
    user = QueuedUser(
        session_id=session_id, 
        session_token=token,
        gender=gender,
        websocket=ws
    )
    
    match_result = await mm_service.join_queue(user)
    
    if match_result:
        # Eşleşme oldu!
        connection_id, partner_id, is_initiator = match_result
        
        # Kendimize bildir
        await send_json(ws, {
            "type": "MATCH_FOUND",
            "connection_id": str(connection_id),
            "is_initiator": is_initiator
        })
        
        # Partnera bildir
        partner_ws = mm_service.get_websocket(partner_id)
        if partner_ws:
            await send_json(partner_ws, {
                "type": "MATCH_FOUND",
                "connection_id": str(connection_id),
                "is_initiator": not is_initiator
            })
    else:
        # Kuyruğa alındık
        position = await mm_service.get_queue_position(session_id)
        online_count = mm_service.online_count
        await send_json(ws, {
            "type": "QUEUE_POSITION",
            "position": position or 1,
            "online_count": online_count
        })
        
        # Tüm bağlı WebSocket'lere online count güncellemesi gönder
        all_websockets = mm_service.get_all_websockets()
        for sid, other_ws in all_websockets.items():
            if sid != session_id:
                try:
                    await send_json(other_ws, {
                        "type": "ONLINE_COUNT_UPDATE",
                        "count": online_count
                    })
                except Exception:
                    pass  # Ignore errors


async def handle_next(session_id: UUID):
    """Mevcut eşleşmeyi bitir ve yeniden kuyruğa gir"""
    partner_id = await mm_service.end_connection(session_id, "NEXTED")
    
    if partner_id:
        await notify_partner_end(partner_id, "NEXTED")
    
    # Kendimize de bittiğini bildir (UI reset için)
    ws = mm_service.get_websocket(session_id)
    if ws:
        await send_json(ws, {
             "type": "MATCH_ENDED",
             "reason": "NEXTED"
        })


async def forward_signal(session_id: UUID, message: dict):
    """WebRTC sinyalini partnera ilet"""
    partner_id = await mm_service.get_partner_session_id(session_id)
    if not partner_id:
        return
        
    partner_ws = mm_service.get_websocket(partner_id)
    if partner_ws:
        await send_json(partner_ws, message)


async def forward_chat(session_id: UUID, message: dict):
    """Chat mesajını partnera ilet"""
    partner_id = await mm_service.get_partner_session_id(session_id)
    if not partner_id:
        return
        
    partner_ws = mm_service.get_websocket(partner_id)
    if partner_ws:
        # Mesaj güvenliği/filtreleme burada yapılabilir
        await send_json(partner_ws, {
            "type": "CHAT_MESSAGE",
            "text": message.get("text", "")
        })


async def notify_partner_end(partner_id: UUID, reason: str):
    """Partnera eşleşmenin bittiğini bildir"""
    partner_ws = mm_service.get_websocket(partner_id)
    if partner_ws:
        await send_json(partner_ws, {
            "type": "MATCH_ENDED",
            "reason": reason
        })


async def send_json(ws: WebSocket, data: dict):
    try:
        await ws.send_text(json.dumps(data))
    except Exception:
        pass  # Connection might be closed, ignore
