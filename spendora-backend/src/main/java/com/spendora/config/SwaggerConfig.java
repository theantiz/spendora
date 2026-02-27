package com.spendora.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class SwaggerConfig {

    @Bean
    OpenAPI spendoraOpenApi() {
        String schemeName = "basicAuth";
        return new OpenAPI()
                .info(new Info()
                        .title("Spendora Backend API")
                        .version("v1")
                        .description("AI-assisted personal finance API for tracking, categorization, and analytics.")
                        .contact(new Contact().name("Spendora Team"))
                        .license(new License().name("Proprietary")))
                .addSecurityItem(new SecurityRequirement().addList(schemeName))
                .schemaRequirement(
                        schemeName,
                        new SecurityScheme()
                                .name(schemeName)
                                .type(SecurityScheme.Type.HTTP)
                                .scheme("basic"));
    }
}
