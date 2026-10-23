package com.dinomic.blockbet.security;

import com.dinomic.blockbet.enums.AccountRole;
import com.dinomic.blockbet.security.filters.JwtAuthenticationFilter;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.config.annotation.authentication.builders.AuthenticationManagerBuilder;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Autowired
    JwtAuthenticationFilter jwtAuthenticationFilter;

    @Autowired
    private AuthenticationProvider authenticationProvider;

    @Autowired
    AuthenticationEntryPoint authEntryPoint;

    @Bean
    public SecurityFilterChain applicationSecurity (HttpSecurity http) {
        http.addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);

        http
                .csrf(AbstractHttpConfigurer::disable)
                .cors(AbstractHttpConfigurer::disable)
                .securityMatcher("/**")
                .authorizeHttpRequests(registry -> registry
                        .requestMatchers("/test/*").permitAll()
                        .requestMatchers("/v3/api-docs/**",
                         "/v3/api-docs.yaml",
                         "/swagger-ui/**",
                         "/swagger-ui.html").permitAll()
                        .requestMatchers("/auth/**").permitAll()
                        .requestMatchers("/bettor/**").hasAnyRole(AccountRole.ROLE_BOOKIE.getRole(), AccountRole.ROLE_BETTOR.getRole())
                        .anyRequest().authenticated())
                .exceptionHandling((httpSecurityExceptionHandlingConfigurer ->
                        httpSecurityExceptionHandlingConfigurer.authenticationEntryPoint(authEntryPoint)));

        return http.build();
    }

    @Bean
    public AuthenticationManager authenticationManager(HttpSecurity http) {
        return http.getSharedObject(AuthenticationManagerBuilder.class)
                .authenticationProvider(authenticationProvider)
                .parentAuthenticationManager(null)
                .build();
    }

}
