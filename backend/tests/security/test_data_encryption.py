import pytest

class TestDataEncryption:
    """Testes de criptografia de dados"""
    
    def test_password_hashing(self):
        """Verificar que senhas são hasheadas"""
        from core.security.password import hash_password, verify_password
        
        password = "TestPassword123"
        hashed = hash_password(password)
        
        # Hash deve ser diferente da senha original
        assert hashed != password
        # Deve ser possível verificar com a senha correta
        assert verify_password(password, hashed) == True
        # Não deve verificar com senha incorreta
        assert verify_password("WrongPassword", hashed) == False