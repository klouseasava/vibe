from fastapi import FastAPI, HTTPException, Body, WebSocket, WebSocketDisconnect, Request, File, UploadFile, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, EmailStr
from typing import List, Optional, Dict
from motor.motor_asyncio import AsyncIOMotorClient
from bson import ObjectId
import datetime
import uvicorn
import json
import os
import re 

app = FastAPI(title="Vibe AI Brain")

# --- DIRECTORY SETUP ---
os.makedirs("static/avatars", exist_ok=True)
os.makedirs("static/signs", exist_ok=True) 
app.mount("/static", StaticFiles(directory="static"), name="static")

templates = Jinja2Templates(directory="templates")

# --- CORS SETUP ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- DATABASE SETUP ---
client = AsyncIOMotorClient("mongodb://localhost:27017")
db = client.vibe_db
signs_collection = db.pending_signs
users_collection = db.users 
rooms_collection = db.rooms 
dictionary_collection = db.sign_dictionary 

# --- AI CONFIGURATION ---
AI_SIGN_MAP = {
    "hello": "/static/signs/hello.mp4",
    "jambo": "/static/signs/jambo.mp4",
    "teacher": "/static/signs/teacher.mp4",
    "help": "/static/signs/help.mp4",
    "please": "/static/signs/please.mp4",
    "thank you": "/static/signs/thanks.mp4"
}

# --- MODELS ---
class Landmark(BaseModel):
    x: float
    y: float
    z: float

class SignData(BaseModel):
    user_id: str
    landmarks: List[Landmark]

class EducateSign(BaseModel):
    user_id: str
    sign_name: str
    country: str
    landmarks: List[Landmark]

class UserAuth(BaseModel):
    email: EmailStr
    password: str
    username: Optional[str] = None

class SpeechRequest(BaseModel):
    text: str
    country: str

# NEW: Dictionary Entry Model
class DictionaryEntry(BaseModel):
    sign_name: str
    country: str
    category: str = "General"
    video_url: str

# --- HTTP ENDPOINTS ---

@app.get("/")
def read_root():
    return {
        "status": "Vibe Brain is Online",
        "version": "1.7.0",
        "capabilities": ["Dictionary API", "NLP Keyword Extraction", "WebSockets", "MongoDB"]
    }

# --- DICTIONARY REFERENCE ENDPOINTS ---

@app.get("/dictionary")
async def get_full_dictionary(
    search: Optional[str] = None, 
    country: Optional[str] = "Kenya",
    category: Optional[str] = None
):
    """
    Fetches verified signs for the Reference Dictionary used by the Deaf community.
    """
    query = {"country": country}
    
    if search:
        # Case-insensitive partial matching for search
        query["sign_name"] = {"$regex": search, "$options": "i"}
    
    if category:
        query["category"] = category

    cursor = dictionary_collection.find(query).sort("sign_name", 1)
    results = []
    async for doc in cursor:
        doc["_id"] = str(doc["_id"])
        results.append(doc)
        
    # If MongoDB is empty, return the AI_SIGN_MAP as basic reference
    if not results and not search and not category:
        for name, url in AI_SIGN_MAP.items():
            results.append({
                "sign_name": name,
                "video_url": url,
                "country": "Universal",
                "category": "Basic"
            })
            
    return results

@app.get("/dictionary/categories")
async def get_categories():
    """Returns a list of available sign categories."""
    categories = await dictionary_collection.distinct("category")
    return categories if categories else ["General", "Greetings", "Family", "Emergency"]

# --- AI TRANSLATION ENGINE ---

@app.post("/translate/sign-to-text")
async def translate_sign(data: SignData):
    if not data.landmarks:
        return {"translation": "...", "confidence": 0.0}

    match = await dictionary_collection.find_one({
        "landmarks": {"$exists": True} 
    })

    if match:
        return {
            "translation": match["sign_name"],
            "confidence": 0.95,
            "verbal_audio": f"/static/audio/{match['sign_name']}.mp3"
        }
    
    return {"translation": "Analyzing gesture...", "confidence": 0.0}

@app.post("/translate/text-to-sign")
async def verbal_to_sign(data: SpeechRequest):
    clean_text = re.sub(r'[^\w\s]', '', data.text.lower()).strip()
    words = clean_text.split()
    
    found_assets = []

    for word in words:
        sign_entry = await dictionary_collection.find_one({
            "sign_name": word,
            "country": data.country
        })
        
        if sign_entry:
            found_assets.append({
                "word": word, 
                "url": sign_entry.get("video_url", "/static/signs/default.mp4")
            })
        elif word in AI_SIGN_MAP:
            found_assets.append({
                "word": word, 
                "url": AI_SIGN_MAP[word]
            })

    if found_assets:
        return {
            "original_text": data.text,
            "interpretation": [item["word"] for item in found_assets],
            "video_urls": [item["url"] for item in found_assets],
            "found": True
        }
    
    return {
        "message": f"AI is still learning the signs for: {data.text}",
        "found": False
    }

# --- AUTHENTICATION SYSTEM ---

@app.post("/signup")
async def signup(user: UserAuth):
    existing_user = await users_collection.find_one({"email": user.email})
    if existing_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    new_user = {
        "username": user.username or user.email.split('@')[0],
        "email": user.email,
        "password": user.password, 
        "vibe_points": 100, 
        "unlocked_voices": ["Default"],
        "level": 1,
        "rank": "Newbie",
        "profile_pic": None,
        "created_at": datetime.datetime.utcnow()
    }
    
    result = await users_collection.insert_one(new_user)
    return {"message": "User created successfully", "user_id": str(result.inserted_id)}

@app.post("/login")
async def login(credentials: UserAuth):
    user = await users_collection.find_one({
        "email": credentials.email, 
        "password": credentials.password
    })
    
    if not user:
        raise HTTPException(status_code=401, detail="Invalid email or password")
    
    return {
        "message": "Login successful",
        "username": user["username"],
        "vibe_points": user["vibe_points"],
        "user_id": str(user["_id"])
    }

# --- GAMIFICATION & USER PROFILE ---

@app.get("/user/{user_id}")
async def get_user_profile(user_id: str):
    user = None
    try:
        if ObjectId.is_valid(user_id):
            user = await users_collection.find_one({"_id": ObjectId(user_id)})
        if not user:
            user = await users_collection.find_one({"user_id": user_id})
    except:
        pass

    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    user["_id"] = str(user["_id"])
    return user

@app.post("/upload-avatar/{user_id}")
async def upload_avatar(user_id: str, file: UploadFile = File(...)):
    file_path = f"static/avatars/{user_id}.jpg"
    with open(file_path, "wb") as buffer:
        buffer.write(await file.read())
    
    image_url = f"/static/avatars/{user_id}.jpg"
    query = {"_id": ObjectId(user_id)} if ObjectId.is_valid(user_id) else {"user_id": user_id}
    await users_collection.update_one(query, {"$set": {"profile_pic": image_url}})
    return {"message": "Profile picture updated", "url": image_url}

# --- WEBSOCKET ENDPOINT ---

active_rooms: Dict[str, List[WebSocket]] = {}

@app.websocket("/ws/vibe/{room_id}")
async def websocket_vibe(websocket: WebSocket, room_id: str):
    await websocket.accept()
    
    if room_id not in active_rooms:
        active_rooms[room_id] = []
    active_rooms[room_id].append(websocket)
    
    try:
        while True:
            data_text = await websocket.receive_text()
            data_json = json.loads(data_text)
            
            response = {
                "translation": "AI Processing Gesture...", 
                "confidence": 0.98,
                "sender": data_json.get("user_id", "Anonymous"),
                "timestamp": datetime.datetime.now().isoformat()
            }
            
            for client_ws in active_rooms[room_id]:
                await client_ws.send_json(response)
            
    except WebSocketDisconnect:
        if websocket in active_rooms[room_id]:
            active_rooms[room_id].remove(websocket)
        if not active_rooms[room_id]:
            del active_rooms[room_id]

# --- COMMUNITY & EDUCATION ENDPOINTS ---

@app.post("/educate")
async def educate_vibe(data: EducateSign):
    new_sign = {
        "sign_name": data.sign_name.strip().lower(),
        "country": data.country,
        "landmarks": [l.dict() for l in data.landmarks],
        "submitted_by": data.user_id,
        "verifications": [],
        "verification_count": 0,
        "status": "pending",
        "created_at": datetime.datetime.utcnow()
    }
    result = await signs_collection.insert_one(new_sign)
    
    await users_collection.update_one(
        {"user_id": data.user_id},
        {"$inc": {"vibe_points": 50}},
        upsert=True
    )
    
    return {
        "message": f"Vibe is learning '{data.sign_name}'",
        "points_awarded": 50,
        "entry_id": str(result.inserted_id)
    }

@app.post("/verify/{sign_id}")
async def verify_sign(sign_id: str, verifier_id: str = Body(..., embed=True)):
    try:
        obj_id = ObjectId(sign_id)
    except:
        raise HTTPException(status_code=400, detail="Invalid Sign ID format")

    sign = await signs_collection.find_one({"_id": obj_id})
    if not sign:
        raise HTTPException(status_code=404, detail="Sign not found")
    
    if verifier_id in sign["verifications"]:
        return {"message": "Already verified", "points_earned": 0}

    new_count = sign["verification_count"] + 1
    
    await signs_collection.update_one(
        {"_id": obj_id},
        {
            "$push": {"verifications": verifier_id},
            "$set": {"verification_count": new_count}
        }
    )

    await users_collection.update_one(
        {"user_id": verifier_id},
        {"$inc": {"vibe_points": 10}},
        upsert=True
    )

    return {
        "sign_name": sign["sign_name"],
        "current_verifications": new_count,
        "vibe_points_earned": 10,
        "is_ready_for_promotion": new_count >= 100
    }

@app.get("/pending_signs")
async def get_pending_signs(country: Optional[str] = None):
    query = {"status": "pending"}
    if country:
        query["country"] = country

    cursor = signs_collection.find(query).sort("created_at", -1)
    pending_list = []
    async for doc in cursor:
        doc["_id"] = str(doc["_id"])
        pending_list.append(doc)
    return pending_list

# --- ADMIN DASHBOARD ---

@app.get("/admin/dashboard", response_class=HTMLResponse)
async def admin_dashboard(request: Request):
    total_pending = await signs_collection.count_documents({"status": "pending"})
    total_verified = await signs_collection.count_documents({"status": "verified"})
    
    ready_cursor = signs_collection.find(
        {"verification_count": {"$gte": 100}, "status": "pending"}
    )
    ready_for_training = []
    async for doc in ready_cursor:
        doc["_id"] = str(doc["_id"])
        ready_for_training.append(doc)

    pipeline = [
        {"$group": {"_id": "$country", "count": {"$sum": 1}}},
        {"$sort": {"count": -1}}
    ]
    country_stats = await signs_collection.aggregate(pipeline).to_list(length=20)

    return templates.TemplateResponse("dashboard.html", {
        "request": request,
        "total_pending": total_pending,
        "total_verified": total_verified,
        "ready_for_training": ready_for_training,
        "country_stats": country_stats
    })

@app.post("/admin/approve-batch")
async def approve_batch():
    ready_signs = signs_collection.find({"verification_count": {"$gte": 100}, "status": "pending"})
    
    count = 0
    async for sign in ready_signs:
        await dictionary_collection.insert_one({
            "sign_name": sign["sign_name"],
            "country": sign["country"],
            "landmarks": sign["landmarks"],
            "category": "Verified",
            "video_url": sign.get("video_url", f"/static/signs/{sign['sign_name']}.mp4")
        })
        await signs_collection.update_one({"_id": sign["_id"]}, {"$set": {"status": "verified"}})
        count += 1
        
    return {"message": f"Successfully promoted {count} signs to the AI Dictionary."}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)