package com.insurit.instrument.entity;

import java.io.Serializable;
import java.math.BigDecimal;
import java.util.Objects;
import javax.persistence.Cacheable;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.NamedQueries;
import javax.persistence.NamedQuery;
import javax.persistence.Table;
import javax.xml.bind.annotation.XmlRootElement;

/**
 *
 * @author Vasilis Stergioulis
 */
@Entity
@Table(name = "INSTRUMENTATION_METRICS")
@Cacheable(false)
@XmlRootElement
@NamedQueries({
    @NamedQuery(name = "InstrumentationMetrics.findAll", query = "SELECT a FROM InstrumentationMetrics a")})
public class InstrumentationMetrics implements Serializable {

    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE,
            generator = "INSTRUMENTATION_METRICS_SEQ")
    @Column(name = "IM_ID")
    long id;

    @Column(name = "IM_METRIC")
    String metric;

    @Column(name = "IM_VALUE")
    BigDecimal value;

    @Column(name = "IM_TYPE")
    String type;

    @Column(name = "IM_HELP")
    String help;

    public InstrumentationMetrics() {
    }

    public long getId() {
        return id;
    }

    public String getMetric() {
        return metric;
    }

    public void setMetric(String metric) {
        this.metric = metric;
    }

    public BigDecimal getValue() {
        return value;
    }

    public void setValue(BigDecimal value) {
        this.value = value;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public String getHelp() {
        return help;
    }

    public void setHelp(String help) {
        this.help = help;
    }

    @Override
    public String toString() {
        return "InstrumentationMetrics{" + "id=" + id + ", metric=" + metric + ", value=" + value + ", type=" + type + ", help=" + help + '}';
    }

    @Override
    public int hashCode() {
        int hash = 3;
        hash = 37 * hash + (int) (this.id ^ (this.id >>> 32));
        hash = 37 * hash + Objects.hashCode(this.metric);
        hash = 37 * hash + Objects.hashCode(this.value);
        hash = 37 * hash + Objects.hashCode(this.type);
        hash = 37 * hash + Objects.hashCode(this.help);
        return hash;
    }

    @Override
    public boolean equals(Object obj) {
        if (this == obj) {
            return true;
        }
        if (obj == null) {
            return false;
        }
        if (getClass() != obj.getClass()) {
            return false;
        }
        final InstrumentationMetrics other = (InstrumentationMetrics) obj;
        if (this.id != other.id) {
            return false;
        }
        if (!Objects.equals(this.metric, other.metric)) {
            return false;
        }
        if (!Objects.equals(this.type, other.type)) {
            return false;
        }
        if (!Objects.equals(this.help, other.help)) {
            return false;
        }
        if (!Objects.equals(this.value, other.value)) {
            return false;
        }
        return true;
    }
}
