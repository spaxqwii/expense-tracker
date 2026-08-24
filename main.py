from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from datetime import date
from dynamo_db import create_expense as db_create, list_expenses as db_list, delete_expense as db_delete
from prometheus_client import Counter, Histogram, generate_latest
from fastapi.responses import Response
import time

# Define metrics
request_count = Counter('expense_tracker_requests_total', 'Total requests', ['method', 'endpoint'])
request_duration = Histogram('expense_tracker_request_duration_seconds', 'Request duration', ['endpoint'])


app = FastAPI()

# Middleware to track metrics
@app.middleware("http")
async def track_metrics(request, call_next):
    start = time.time()
    response = await call_next(request)
    duration = time.time() - start
    request_count.labels(method=request.method, endpoint=request.url.path).inc()
    request_duration.labels(endpoint=request.url.path).observe(duration)
    return response

@app.get("/metrics")
def metrics():
    return Response(generate_latest(), media_type="text/plain")

class Expense(BaseModel):
    amount: float
    category: str
    description: str
    date: date

@app.get("/")
def read_root():
    return {"message": "Expense tracker API is running"}

@app.post("/expenses")
def create_expense(expense: Expense):
    return db_create(expense.dict())

@app.get("/expenses")
def list_expenses():
    return db_list()

@app.get("/expenses/summary")
def summary():
    expenses = db_list()
    totals = {}
    for exp in expenses:
        totals[exp["category"]] = totals.get(exp["category"], 0) + float(exp["amount"])
    return totals

@app.delete("/expenses/{expense_id}")
def delete_expense(expense_id: str):
    if not db_delete(expense_id):
        raise HTTPException(status_code=404, detail="Expense not found")
    return {"message" : f"Expense {expense_id} deleted"}


