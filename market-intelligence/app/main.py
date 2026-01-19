from fastapi import FastAPI
from app.api import insights

app = FastAPI(title="Hawkeye Market Intelligence")

app.include_router(insights.router, prefix="/api/v1", tags=["insights"])

@app.get("/")
def read_root():
    return{"status": "online", "service":"Hawkeye"}

@app.get("/health")
def health_check():
    return {"status":"healthy"}