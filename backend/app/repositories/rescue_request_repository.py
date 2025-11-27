from abc import ABC, abstractmethod
from app.models import RescueRequest, ConditionType
from typing import Optional, List


class IRescueRequestRepo(ABC):
    @abstractmethod
    def create(self, **kwagrs) -> RescueRequest:
        pass

class RescueRequestRepo(IRescueRequestRepo):
    def create(self, **kwagrs) -> RescueRequest:
        return RescueRequest.objects.create(**kwagrs)
    

class ConditionTypeRepo:
    
    def create(self, name: str) -> ConditionType:
        return ConditionType.objects.create(name=name)
    
    def get(self, id: str) -> Optional[ConditionType]:
        return ConditionType.objects.filter(id=id).first()
    
    def list(self) -> List[ConditionType]:
        return list(ConditionType.objects.all())
    
    def update(self, id: str, name: str) -> Optional[ConditionType]:
        obj = self.get(id)
        if obj:
            obj.name = name
            obj.save()
        return obj
    
    def delete(self, id: str) -> bool:
        obj = self.get(id)
        if obj:
            obj.delete()
            return True
        return False