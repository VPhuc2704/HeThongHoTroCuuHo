from app.models import Role
from abc import ABC, abstractmethod

class IRoleRepo(ABC):
    @abstractmethod
    def get_by_code(self, code: str):
        pass

class RoleRepo(IRoleRepo):
    def get_by_code(self, code: str):
        return Role.objects.get(code=code)
