from enum import Enum

class RescueStatus(str, Enum):
    PENDING = "PENDING"
    ASSIGNED = "ASSIGNED"
    IN_PROGRESS = "IN_PROGRESS"
    COMPLETED = "COMPLETED"
    SAFE = "SAFE"      

RESCUE_STATUS = {
    RescueStatus.PENDING: "Chờ xử lý",
    RescueStatus.ASSIGNED: "Đã phân công",
    RescueStatus.IN_PROGRESS: "Đang thực hiện",
    RescueStatus.COMPLETED: "Hoàn thành",
    RescueStatus.SAFE: "An Toàn",
}

class TaskStatus(str, Enum):
    ASSIGNED    = 'Đã điều động'
    IN_PROGRESS = 'Đang di chuyển'
    ARRIVED     = 'Đã đến'
    COMPLETED   = 'Hoàn thành'

class TeamStatus(str, Enum):
    AVAILABLE = 'Sẵn sàng'
    BUSY      = 'Đang bận'
    OFFLINE   = 'Ngoại tuyến'