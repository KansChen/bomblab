# Background

这是一份南京邮电大学计算机系统课程设计实践周的项目。来源是CMU的CSAPP的BOMB LAB。

目标如下：

题目描述：针对《计算机系统基础》课程炸弹程序存在问题，进行程序升级，方便教师对学生的炸弹实验情况及时进行监督和管理。

## 基本要求

(1)编写程序使教师可以及时通过页面查询班上学生的实验进展情况；   

(2) 编写程序可对实验成绩进行管理。

(3)实物演示时要求讲出程序原理和设计思想；

(4)程序运行良好、界面清晰。

## 报告要求： 

（1）撰写报告，对所采用的设计方案、算法、程序结构和主要函数过程以及关键变量进行详细的说明；对程序的调试过程所遇到的问题进行回顾和分析，对测试和运行结果进行分析；总结软设计和实习的经验和体会，进一步改进的设想。

（2）提供关键程序的清单、源程序及可执行文件和相关的软件说明。

# Install
开发者的环境

Windows 11的Windows Subsystem for Linux 2

OS：Ubuntu 22.04

CPU：Intel x86-64

这个项目用到了`build-essential`，以及perl的`Text::CSV`。如果你没有安装，请安装它们。

为了方便，请切换到root用户，赋予777权限。

在第一次使用时，输入
```
make cleanallfiles
make start
```
这会重新构建整个项目，并开始运行服务。
如果你需要停止，输入
```
make stop
```

常见的环境变量设置有SERVER_IP,hostname，请修改或增加为你需要的值，默认是127.0.0.1。更多请参照原项目的文档。
`./name_list.csv`存储了学生名单，它的格式如下：
```csv
student_id,student_name,teacher_name,class_id
B22040001,王雨露,niuma,B220400
B22040002,何懿琳,niuma,B220400
B22040003,范诗瑜,niuma,B220400
B22040004,谢睿琪,niuma,B220400
```
这会影响scoreboard的显示效果，你可以修改它，然后重新构建项目。

# Usage
如果一切没有问题，在你的浏览器中输入`http://localhost:15213`，你应该会得到这样一个界面。
[![pAynJOA.png](https://s21.ax1x.com/2024/11/07/pAynJOA.png)](https://imgse.com/i/pAynJOA)

剩下的使用请参照原项目的文档，我并没有修改逻辑。

# Development

这个项目相较于原项目，修改了request、update的代码。通过现代的HTML5,JS,CSS语言让登录界面变得更加美观。update部分通过载入CSV，新增了动态筛选、搜索功能。能够让老师、学生更方便地看到不同视图的成绩。
