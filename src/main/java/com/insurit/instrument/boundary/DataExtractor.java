package com.insurit.instrument.boundary;

import com.insurit.instrument.entity.InstrumentationMetrics;
import java.util.List;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.persistence.TypedQuery;

/**
 *
 * @author Vasilis Stergioulis
 */
public class DataExtractor {

    @PersistenceContext(name = "db")
    EntityManager em;

    public List<InstrumentationMetrics> getAllMetrics() {
        TypedQuery<InstrumentationMetrics> query = em.createNamedQuery("InstrumentationMetrics.findAll", InstrumentationMetrics.class);
        return query.getResultList();
    }

}
