from fastapi import FastAPI

app = FastAPI(title="Hawkeye Market Intelligence")

@app.get("/")
def read_root():
    return{"status": "online", "service":"Hawkeye"}

@app.get("/health")
def health_check():
    return {"status":"healthy"}