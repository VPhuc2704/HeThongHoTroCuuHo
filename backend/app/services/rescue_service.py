from typing import List
from app.models import RescueTeam
from django.db import transaction, connection
from app.schemas.rescue_schema import RescueTeamUpdate, RescueTeamOut
from app.exception.custom_exceptions import ResourceNotFound, PermissionDenied
from app.enum.role_enum import RoleCode


class RescueService:
    
    def get_teams(user) -> List[RescueTeamOut]:
        if user.role.code == RoleCode.ADMIN:
            sql = """
                SELECT id, name , leader_name, contact_phone, hotline, 
                        team_type, address, primary_area, status, created_at,
                        ST_X(location) AS longitude, 
                        ST_Y(location) AS latitude
                FROM rescue_teams
                ORDER BY created_at DESC;
            """ 
            with connection.cursor() as cursor:
                cursor.execute(sql)
                rows = cursor.fetchall()
                
                columns = [col[0] for col in cursor.description]

            result = []

            for row in rows:
                row_dict = {}
                for index in range(len(columns)):
                    column_name = columns[index]
                    row_dict[column_name] = row[index]

                team = RescueTeamOut(**row_dict)
                result.append(team)

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
            RETURNING id, name , leader_name, contact_phone, hotline, 
                    team_type, address, primary_area, status, created_at,
                    ST_X(location) AS longitude, 
                    ST_Y(location) AS latitude;
        """

        with connection.cursor() as cursor:
            cursor.execute(sql, values)

            updated_team = cursor.fetchone()

            if not updated_team:
                return None
            
            columns = [col[0] for col in cursor.description]

            row_dict = dict(zip(columns, updated_team))

            return RescueTeamOut(
                **row_dict
            )


    def delete_team(team_id: str):
        try:
            team = RescueTeam.objects.get(id=team_id)
            team.delete()
            return True
        except RescueTeam.DoesNotExist:
            raise ResourceNotFound("Đội cứu hộ không tồn tại")