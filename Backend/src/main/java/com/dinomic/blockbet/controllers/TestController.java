package com.dinomic.blockbet.controllers;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/test")
public class TestController {
    @GetMapping("/num1")
    public String testNum1() {
        System.out.println("hehehe");
        return "test num 1 OK";
    }
}
