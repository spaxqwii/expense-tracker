import boto3
import uuid
from decimal import Decimal

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("expenses")

def create_expense(expense_data: dict):
    expense_id = str(uuid.uuid4())
    item = {
        "id": expense_id,
        "amount": Decimal(str(expense_data["amount"])),
        "category": expense_data["category"],
        "description": expense_data["description"],
        "date": expense_data["date"].isoformat(),
    }
    table.put_item(Item=item)
    return item

def list_expenses():
    response = table.scan()
    return response.get("Items", [])

def delete_expense(expense_id: str):
    response = table.get_item(Key={"id": expense_id})
    if "Item" not in response:
        return False
    table.delete_item(Key={"id": expense_id})
    return True
