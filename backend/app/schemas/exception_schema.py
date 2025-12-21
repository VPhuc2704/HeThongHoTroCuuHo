from ninja.schema import Schema
from typing import Optional, TypeVar, Generic, Any

T = TypeVar("T")

class ApiResponse(Schema, Generic[T]):
    success: bool
    code: int
    message: str
    data: Optional[T] = None
    details: Optional[Any] = None