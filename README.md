# Deployments
开发者的环境

环境：Windows 11的Windows Subsystem for Linux 2

OS：Ubuntu 22.04

CPU：Intel x86-64

推荐安装`build-essential`，以及perl的`Text::CSV`，以及perl的`URI::Escape`。

需要在pm中加入自己的`hostname`。

1. 与main分支不一样的是，request界面新增了数据字段验证。部署时还需要有`./name_list_zy.csv`文件。
格式如下：
```csv
student_id,student_name,teacher_name,class_id
B22040001,wang,niuma,B220400
B22040002,zhanyi,niuma,B220400
```
因为author@展翼在重构student_name时没有考虑中文编码的问题，即不支持UTF-8，所以这一部分必须是英文。

2. scoreboard的显示逻辑变成了显示全体学生，即便其没有有效的提交记录。
修改了for_each的部分代码。

3. 修改了6个炸弹的内容，降低了学生反汇编的难度。
