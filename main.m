//
//  main.m
//  LittleDrop
//
//  Created by Sergio Rubio on 5/12/09.
//  Copyright CSIC 2009. All rights reserved.
//

#import <MacRuby/MacRuby.h>
#import <AppKit/AppKit.h>
#import <DropIO.h>

int main(int argc, char *argv[])
{
    return macruby_main("rb_main.rb", argc, argv);
}
