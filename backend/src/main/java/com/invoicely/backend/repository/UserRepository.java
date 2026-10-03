package com.invoicely.backend.repository;

import com.invoicely.backend.model.Role;
import com.invoicely.backend.model.User;
import com.invoicely.backend.model.UserStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);
    Optional<User> findByMobile(String mobile);
    Optional<User> findByEmailOrMobile(String email, String mobile);
    boolean existsByEmail(String email);
    List<User> findByCompanyId(Long companyId);
    List<User> findByCompanyIdAndStatus(Long companyId, UserStatus status);
    List<User> findByRole(Role role);
}
