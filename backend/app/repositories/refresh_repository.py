from ..models import RefreshToken
from abc import ABC, abstractmethod

from typing import Optional

class IRefreshRepo(ABC):
    @abstractmethod
    def find_by_token(self, token: str) -> Optional[RefreshToken]: 
        pass

class RefreshRepo(IRefreshRepo):
    def find_by_token(self, token) -> Optional[RefreshToken]:

        return RefreshToken.objects.filter(token=token).first()

