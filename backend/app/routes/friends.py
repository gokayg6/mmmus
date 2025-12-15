"""
Friends Routes
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session, aliased
from typing import List
from uuid import UUID

from app.database import get_db
from app.routes.auth import get_current_user
from app.models.user import User
from app.models.friendship import Friendship, FriendshipStatus
from app.schemas.chat import FriendRequestCreate, FriendshipResponse, FriendResponse
from app.services.matchmaking import get_matchmaking_service

router = APIRouter(prefix="/friends", tags=["Friends"])

@router.post("/request", response_model=FriendshipResponse)
def send_friend_request(
    request: FriendRequestCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Target user exists?
    target_user = db.query(User).filter(User.username == request.username).first()
    if not target_user:
        raise HTTPException(status_code=404, detail="User not found")
    
    if target_user.id == current_user.id:
        raise HTTPException(status_code=400, detail="Cannot add yourself")

    # Already friends?
    existing = db.query(Friendship).filter(
        ((Friendship.user_id == current_user.id) & (Friendship.friend_id == target_user.id)) |
        ((Friendship.user_id == target_user.id) & (Friendship.friend_id == current_user.id))
    ).first()

    if existing:
        if existing.status == FriendshipStatus.ACCEPTED:
            raise HTTPException(status_code=400, detail="Already friends")
        if existing.status == FriendshipStatus.PENDING:
            raise HTTPException(status_code=400, detail="Friend request already pending")
        # If blocked or rejected, logic might differ, for now simple:
        raise HTTPException(status_code=400, detail="Cannot send request")

    # Create request
    friendship = Friendship(
        user_id=current_user.id,
        friend_id=target_user.id,
        status=FriendshipStatus.PENDING
    )
    db.add(friendship)
    db.commit()
    db.refresh(friendship)
    
    # Return formatted response
    return FriendshipResponse(
        id=friendship.id,
        friend=FriendResponse(id=target_user.id, username=target_user.username, avatar_url=target_user.avatar_url),
        status=FriendshipStatus.PENDING,
        created_at=friendship.created_at
    )

@router.post("/{friendship_id}/accept", response_model=FriendshipResponse)
def accept_friend_request(
    friendship_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    friendship = db.query(Friendship).filter(Friendship.id == friendship_id).first()
    if not friendship:
        raise HTTPException(status_code=404, detail="Request not found")
    
    # Verify recipient is current user
    if friendship.friend_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized")
        
    friendship.status = FriendshipStatus.ACCEPTED
    db.commit()
    
    initiator = db.query(User).filter(User.id == friendship.user_id).first()
    
    return FriendshipResponse(
        id=friendship.id,
        friend=FriendResponse(id=initiator.id, username=initiator.username, avatar_url=initiator.avatar_url),
        status=FriendshipStatus.ACCEPTED,
        created_at=friendship.created_at
    )

@router.get("/", response_model=List[FriendshipResponse])
def get_friends(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Get all accepted friendships where user is either sender or receiver
    friendships = db.query(Friendship).filter(
        ((Friendship.user_id == current_user.id) | (Friendship.friend_id == current_user.id)) &
        (Friendship.status == FriendshipStatus.ACCEPTED)
    ).all()
    
    mm_service = get_matchmaking_service() # We might use this later for online status
    
    results = []
    for f in friendships:
        # Determine who is the "other" person
        is_sender = f.user_id == current_user.id
        raw_friend = f.friend if is_sender else f.user # Relationships loaded by generic FKs or manual query
        
        # Manual fetch because relationships might be tricky with bidirectional same-table
        friend_id = f.friend_id if is_sender else f.user_id
        friend_user = db.query(User).filter(User.id == friend_id).first()
        
        results.append(FriendshipResponse(
            id=f.id,
            friend=FriendResponse(
                id=friend_user.id, 
                username=friend_user.username, 
                avatar_url=friend_user.avatar_url,
                is_online=False # TODO: Implement real online check via MM service or Redis
            ),
            status=f.status,
            created_at=f.created_at
        ))
        
    return results

@router.get("/requests/incoming", response_model=List[FriendshipResponse])
def get_incoming_requests(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    requests = db.query(Friendship).filter(
        (Friendship.friend_id == current_user.id) &
        (Friendship.status == FriendshipStatus.PENDING)
    ).all()
    
    results = []
    for f in requests:
        initiator = db.query(User).filter(User.id == f.user_id).first()
        results.append(FriendshipResponse(
            id=f.id,
            friend=FriendResponse(id=initiator.id, username=initiator.username, avatar_url=initiator.avatar_url),
            status=f.status,
            created_at=f.created_at
        ))
    return results
