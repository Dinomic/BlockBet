package com.dinomic.blockbet.controllers;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/test")
public class TestController {
    private static final Logger log = LoggerFactory.getLogger(TestController.class);

    @GetMapping("/num1")
    public String testNum1() {
        log.info("test num 1 OK");
        return "test num 1 OK";
    }
}
