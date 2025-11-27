from enum import Enum

class RescueStatus(str, Enum):
    PENDING = "PENDING"
    ASSIGNED = "ASSIGNED"
    IN_PROGRESS = "IN_PROGRESS"
    COMPLETED = "COMPLETED"
    SAFE = "SAFE"      

RESCUE_STATUS = {
    RescueStatus.PENDING: "Chờ xữ lý",
    RescueStatus.ASSIGNED: "Đã phân công",
    RescueStatus.IN_PROGRESS: "Đang thực hiện",
    RescueStatus.COMPLETED: "Hoàn thành",
    RescueStatus.SAFE: "An Toàn",
}
