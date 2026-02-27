package com.spendora.analytics.repository;

import java.util.List;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.springframework.stereotype.Repository;

@Repository
public class AnalyticsRepository {

    @PersistenceContext
    private EntityManager entityManager;

    public long countSuggestions() {
        return entityManager.createQuery("select count(a) from AiSuggestion a", Long.class)
                .getSingleResult();
    }

    public long countFeedback() {
        return entityManager.createQuery(
                        "select count(a) from AiSuggestion a where a.validated = true",
                        Long.class)
                .getSingleResult();
    }

    public long countAccepted() {
        return entityManager.createQuery(
                        "select count(a) from AiSuggestion a where a.validated = true and a.overridden = false",
                        Long.class)
                .getSingleResult();
    }

    public long countOverridden() {
        return entityManager.createQuery(
                        "select count(a) from AiSuggestion a where a.validated = true and a.overridden = true",
                        Long.class)
                .getSingleResult();
    }

    public long countGpt() {
        return entityManager.createQuery(
                        "select count(a) from AiSuggestion a where a.source = 'GPT'",
                        Long.class)
                .getSingleResult();
    }

    public List<Object[]> countBySource() {
        return entityManager.createQuery(
                        "select a.source, count(a) from AiSuggestion a group by a.source order by count(a) desc",
                        Object[].class)
                .getResultList();
    }

    public List<Object[]> categoryPrecision() {
        return entityManager.createQuery(
                        """
                        select coalesce(a.finalCategory, a.suggestedCategory),
                               count(a),
                               sum(case when a.overridden = false then 1 else 0 end)
                        from AiSuggestion a
                        where a.validated = true
                        group by coalesce(a.finalCategory, a.suggestedCategory)
                        order by count(a) desc
                        """,
                        Object[].class)
                .getResultList();
    }
}
