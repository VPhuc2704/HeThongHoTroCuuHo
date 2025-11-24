from enum import Enum

class RoleCode(str, Enum):
    CITIZEN = "CITIZEN"
    RESCUER = "RESCUER"
    ADMIN = "ADMIN"

ROLE_DISPLAY_NAME = {
    RoleCode.CITIZEN: "Người dân",
    RoleCode.RESCUER: "Đội cứu hộ",
    RoleCode.ADMIN: "Quản trị viên",
}