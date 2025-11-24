from abc import ABC, abstractmethod
from app.models import RescueTeam

class IRescueTeamRepo(ABC):
    @abstractmethod
    def create(self, **kwargs) -> RescueTeam:
        pass

class RescueTeamRepo(IRescueTeamRepo):
    def create(self, **kwargs) -> RescueTeam:
        return RescueTeam.objects.create(**kwargs)
