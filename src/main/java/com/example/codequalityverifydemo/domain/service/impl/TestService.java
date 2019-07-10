package com.example.codequalityverifydemo.domain.service.impl;

import com.example.codequalityverifydemo.domain.service.ITestService;
import org.springframework.stereotype.Service;

@Service
public class TestService implements ITestService {

    private Integer age;

    public String print(String msg) {
      System.out.println(msg);
      if (age<0 || age > 100){
          System.out.println("年龄写错啦");
      }
        return msg;
    }
}
