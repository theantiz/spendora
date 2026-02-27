package com.spendora.config;

import jakarta.servlet.Servlet;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnClass;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.boot.web.servlet.ServletRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
@ConditionalOnClass(name = "org.h2.server.web.JakartaWebServlet")
@ConditionalOnProperty(prefix = "spring.h2.console", name = "enabled", havingValue = "true")
public class H2ConsoleConfig {

    @Bean
    ServletRegistrationBean<Servlet> h2ConsoleServletRegistration(
            @Value("${spring.h2.console.path:/h2-console}") String h2ConsolePath) {
        String normalizedPath = h2ConsolePath.endsWith("/")
                ? h2ConsolePath.substring(0, h2ConsolePath.length() - 1)
                : h2ConsolePath;
        String wildcardPath = normalizedPath + "/*";

        Servlet h2Servlet = instantiateH2Servlet();
        ServletRegistrationBean<Servlet> registration = new ServletRegistrationBean<>(h2Servlet, normalizedPath, wildcardPath);
        registration.addInitParameter("-trace", "false");
        registration.addInitParameter("-webAllowOthers", "false");
        return registration;
    }

    private Servlet instantiateH2Servlet() {
        try {
            Class<?> servletClass = Class.forName("org.h2.server.web.JakartaWebServlet");
            Object servletInstance = servletClass.getDeclaredConstructor().newInstance();
            return (Servlet) servletInstance;
        } catch (Exception ex) {
            throw new IllegalStateException("Failed to initialize H2 console servlet", ex);
        }
    }
}
