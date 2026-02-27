package com.spendora.ai.repository;

import com.spendora.ai.model.AiSuggestion;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AiSuggestionRepository extends JpaRepository<AiSuggestion, Long> {

    Optional<AiSuggestion> findTopByUserIdAndNormalizedInputAndValidatedTrueOrderByCreatedAtDesc(
            Long userId, String normalizedInput);

    Optional<AiSuggestion> findTopByNormalizedInputAndValidatedTrueAndOverriddenTrueOrderByCreatedAtDesc(
            String normalizedInput);

    List<AiSuggestion> findByValidatedTrueOrderByCreatedAtAsc();
}
