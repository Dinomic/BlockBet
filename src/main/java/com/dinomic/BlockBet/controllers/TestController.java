package com.dinomic.BlockBet.controllers;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/test")
public class TestController {

    @GetMapping("/num1")
    public String testNum1() {
//        System.out.println(testService);
        return "test num 1 OK";
    }

    @GetMapping("/num2")
    public String testNum2() {
//        System.out.println(testService);
        return "test num 2 OK";
    }
}
