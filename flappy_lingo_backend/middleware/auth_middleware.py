from fastapi import HTTPException, Security
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError
from services.auth_service import decode_token

bearer_scheme = HTTPBearer()

def require_auth(
    credentials: HTTPAuthorizationCredentials = Security(bearer_scheme),
) -> str:
    try:
        user_id = decode_token(credentials.credentials)
        if not user_id:
            raise HTTPException(status_code=401, detail="Token inválido o expirado")
        return user_id
    except JWTError:
        raise HTTPException(status_code=401, detail="Token inválido o expirado")