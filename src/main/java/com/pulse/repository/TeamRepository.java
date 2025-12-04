package com.pulse.repository;

import com.pulse.model.Team;
import com.pulse.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TeamRepository extends JpaRepository<Team, Long> {
    @Query("SELECT t FROM Team t JOIN t.members m WHERE m.user = :user")
    List<Team> findByUserMembership(@Param("user") User user);
}

