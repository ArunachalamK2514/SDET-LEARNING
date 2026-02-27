package com.sdet.portfolio.core.keywords;

import org.testng.Assert;
import org.testng.annotations.Test;

public class KeywordsTest {

    @Test
    public void testFinalKeyword() {
        FinalExample demo = new FinalExample();
        demo.runDemo();
        Assert.assertEquals(FinalExample.BROWSER, "Chrome");
        Assert.assertEquals(FinalExample.TIMEOUT, 30);
    }

    @Test
    public void testFinallyBlockSuccess() {
        FinallyExample demo = new FinallyExample();
        demo.executeTestSimulation(false);
    }

    @Test
    public void testFinallyBlockFailure() {
        FinallyExample demo = new FinallyExample();
        demo.executeTestSimulation(true);
    }

    @Test
    public void testFinallyWithReturn() {
        FinallyExample demo = new FinallyExample();
        String result = demo.demonstrateFinallyWithReturn();
        System.out.println(result);
        Assert.assertEquals(result, "Value from TRY");
    }

    @Test
    public void testFinalizeMethod() {
        FinalizeExample.runDemo();
    }
}
