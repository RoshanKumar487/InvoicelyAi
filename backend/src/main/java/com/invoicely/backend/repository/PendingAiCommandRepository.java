package com.invoicely.backend.repository;

import com.invoicely.backend.model.PendingAiCommand;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface PendingAiCommandRepository extends JpaRepository<PendingAiCommand, String> {

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT command FROM PendingAiCommand command WHERE command.id = :id AND command.userId = :userId AND command.companyId = :companyId")
    Optional<PendingAiCommand> findForUpdate(
            @Param("id") String id,
            @Param("userId") Long userId,
            @Param("companyId") Long companyId);
}
