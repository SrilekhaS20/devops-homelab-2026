package com.devops.demo;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

@RestController
public class HelloController {

    @GetMapping("/")
    public String home() {
        return "Java Spring Boot CI/CD Pipeline - Running Successfully!";
    }

    @GetMapping("/api/hello")
    public String hello() {
        String timestamp = LocalDateTime.now()
            .format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
        return "Hello from Java Spring Boot! Docker Hub integration working! Build" + timestamp;
    }

    @GetMapping("/api/health")
    public String health() {
        return "OK";
    }
}