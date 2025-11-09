import pytest
from core.security.password import hash_password, verify_password

class TestPasswordSecurity:
    """Testes unitários para funções de password"""
    
    def test_hash_password(self):
        """Testar hash de password"""
        password = "TestPassword123"
        hashed = hash_password(password)
        
        assert hashed != password
        assert isinstance(hashed, str)
        assert len(hashed) > 0
    
    def test_verify_correct_password(self):
        """Testar verificação de password correto"""
        password = "TestPassword123"
        hashed = hash_password(password)
        
        assert verify_password(password, hashed) == True
    
    def test_verify_incorrect_password(self):
        """Testar verificação de password incorreto"""
        password = "TestPassword123"
        wrong_password = "WrongPassword123"
        hashed = hash_password(password)
        
        assert verify_password(wrong_password, hashed) == False
    
    def test_different_hashes_for_same_password(self):
        """Testar que hashes são diferentes para a mesma senha (sal diferente)"""
        password = "TestPassword123"
        hash1 = hash_password(password)
        hash2 = hash_password(password)
        
        # Hashes devem ser diferentes devido ao salt
        assert hash1 != hash2
        
        # Mas ambas devem verificar corretamente
        assert verify_password(password, hash1) == True
        assert verify_password(password, hash2) == True
    
    def test_hash_empty_password(self):
        """Testar hash de password vazio"""
        password = ""
        hashed = hash_password(password)
        
        assert hashed != password
        assert verify_password(password, hashed) == True