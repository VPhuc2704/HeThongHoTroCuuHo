from app.models import RescueTeam
from django.db import transaction, connection
from app.schemas.rescue_schema import RescueTeamUpdate, RescueTeamOut
from app.exception.custom_exceptions import ResourceNotFound, PermissionDenied
from app.enum.role_enum import RoleCode


class RescueService:
    
    def get_teams(user):
        if user.role.code == RoleCode.ADMIN:
            sql = """
                SELECT id, name , contact_phone, status,
                        ST_X(location) AS longitude, 
                        ST_Y(location) AS latitude
                FROM rescue_teams
                ORDER BY created_at DESC;
            """ 
            with connection.cursor() as cursor:
                cursor.execute(sql=sql)
                rows = cursor.fetchall()
                result = []
                for r in rows:
                    result.append({
                        "id": r[0],
                        "name": r[1],
                        "contact_phone": r[2],
                        "status": r[3],
                        "longitude": float(r[4]) if r[4] is not None else None,
                        "latitude": float(r[5]) if r[5] is not None else None,
                    })
            return result
        

    def update_rescue_team(account, team_id: str, payload: RescueTeamUpdate) -> RescueTeamOut:
        try:
            team = RescueTeam.objects.get(id=team_id)
        except:
            raise ResourceNotFound("Đội cứu hộ không tồn tại")
        
        is_admin = (account.role.code == RoleCode.ADMIN)
        is_owner = (team.account == account)
        
        if not (is_admin or is_owner):
            raise PermissionDenied("Bạn không có quyền sửa đội này.")
        
        data = payload.model_dump(exclude_unset=True)
        if not data:
            return None

        updates = []
        values = []


        with connection.cursor() as cursor:
            lat = data.pop("latitude", None)
            lng = data.pop("longitude", None)
            if lat is not None and lng is not None:
                try:
                    updates.append("location = ST_SetSRID(ST_MakePoint(%s, %s), 4326)")
                    values.extend([lng, lat])
                except (TypeError, ValueError):
                    raise ValueError("latitude và longitude phải là số hợp lệ")

            for field, value in data.items():
                updates.append(f"{field} = %s")
                values.append(value)

            if not updates:
                return None

            values.append(team_id)
            sql = f"""
                UPDATE rescue_teams
                SET {', '.join(updates)}
                WHERE id = %s
                RETURNING id, name, contact_phone, status,
                        ST_X(location) AS longitude, ST_Y(location) AS latitude;
            """
            cursor.execute(sql, values)

            print("SQL:", sql)
            updated_team = cursor.fetchone()

            if not updated_team:
                return None

            return RescueTeamOut(
                id=updated_team[0],
                name=updated_team[1],
                contact_phone=updated_team[2],
                status=updated_team[3],
                longitude=float(updated_team[4]) if updated_team[4] is not None else None,
                latitude=float(updated_team[5]) if updated_team[5] is not None else None
            )


    def delete_team(team_id: str):
        try:
            team = RescueTeam.objects.get(id=team_id)
            team.delete()
            return True
        except RescueTeam.DoesNotExist:
            raise ResourceNotFound("Đội cứu hộ không tồn tại")