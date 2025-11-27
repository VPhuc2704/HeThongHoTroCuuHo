from abc import ABC, abstractmethod
from ..repositories import IRescueRequestRepo, RescueRequestRepo, ConditionTypeRepo
from ..schemas.rescue_request_schema import RescueRequestSchema
from ..models import RescueRequest
from typing import Optional
from ..models import Account

class IRescueRequestService(ABC):
    @abstractmethod
    def create_request(self, 
                       data: RescueRequestSchema, 
                       account: Optional[Account] = None) -> RescueRequest:
        """
        Tạo một RescueRequest mới từ dữ liệu đã validate.
        """
        pass

class RescueRequestService(IRescueRequestService):
    def __init__(self, rescue_request_repo: IRescueRequestRepo = None):
        self.rescue_request_repo = rescue_request_repo or RescueRequestRepo()

    def create_request(self, 
                       data: RescueRequestSchema, 
                       account: Optional[Account] = None ) -> RescueRequest:

        payload = data.model_dump()  # chuyển Schema sang dict

        if account:
            payload["account"] = account

        # Tạo request bằng repository
        request = self.rescue_request_repo.create(**payload)
        return request
    


class ConditionTypeService:
    def __init__(self, repo: ConditionTypeRepo = None):
        self.repo = repo or ConditionTypeRepo()
    
    def create(self, name: str):
        return self.repo.create(name)
    
    def get(self, id: str):
        return self.repo.get(id)
    
    def list(self):
        return self.repo.list()
    
    def update(self, id: str, name: str):
        return self.repo.update(id, name)
    
    def delete(self, id: str):
        return self.repo.delete(id)