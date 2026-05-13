# Git 和 GitHub 日常工作流

> **文档职责**：提供 Git 和 GitHub 日常开发中的常用命令和工作流参考
> **适用场景**：日常开发时快速查找命令；新成员学习 Git 工作流；解决常见 Git 问题
> **目标读者**：开发者
> **维护规范**：发现常用命令缺失时补充到对应章节；新增常见问题时更新 §6

---

## 一、基础操作

### 1.1 克隆和初始化

```bash
# 克隆远程仓库
git clone <repo-url>

# 克隆指定分支
git clone -b <branch-name> <repo-url>

# 初始化本地仓库
git init

# 查看远程仓库地址
git remote -v

# 添加远程仓库
git remote add origin <repo-url>

# 修改远程仓库地址
git remote set-url origin <new-repo-url>
```

### 1.2 查看状态

```bash
# 查看工作区状态
git status

# 查看状态（简洁版）
git status -s

# 查看差异（未暂存的修改）
git diff

# 查看差异（已暂存的修改）
git diff --staged

# 查看差异（与指定分支）
git diff main

# 查看差异（与指定提交）
git diff <commit-hash>
```

### 1.3 暂存和提交

```bash
# 暂存指定文件
git add <file>

# 暂存所有修改
git add .

# 暂存所有修改（包括删除）
git add -A

# 交互式暂存（选择部分修改）
git add -p

# 提交
git commit -m "提交信息"

# 提交（包含详细描述）
git commit -m "标题" -m "详细描述"

# 修改上一次提交
git commit --amend

# 修改上一次提交信息
git commit --amend -m "新的提交信息"

# 暂存并提交（仅对已跟踪文件有效）
git commit -am "提交信息"
```

---

## 二、分支管理

### 2.1 查看分支

```bash
# 查看本地分支
git branch

# 查看所有分支（包括远程）
git branch -a

# 查看远程分支
git branch -r

# 查看分支详细信息（包含最后一次提交）
git branch -v

# 查看已合并到当前分支的分支
git branch --merged

# 查看未合并到当前分支的分支
git branch --no-merged
```

### 2.2 创建和切换分支

```bash
# 创建新分支
git branch <branch-name>

# 切换分支
git checkout <branch-name>

# 创建并切换到新分支
git checkout -b <branch-name>

# 基于远程分支创建本地分支
git checkout -b <local-branch> origin/<remote-branch>

# 切换分支（新语法）
git switch <branch-name>

# 创建并切换分支（新语法）
git switch -c <branch-name>
```

### 2.3 合并和删除分支

```bash
# 合并指定分支到当前分支
git merge <branch-name>

# 合并时保留合并记录（禁用 fast-forward）
git merge --no-ff <branch-name>

# 删除本地分支
git branch -d <branch-name>

# 强制删除本地分支
git branch -D <branch-name>

# 删除远程分支
git push origin --delete <branch-name>
```

---

## 三、查看历史

### 3.1 基础 log 命令

```bash
# 查看提交历史
git log

# 查看提交历史（简洁版，一行一条）
git log --oneline

# 查看最近 N 条提交
git log -n 5

# 查看提交历史（包含差异）
git log -p

# 查看提交历史（包含统计信息）
git log --stat

# 查看提交历史（图形化显示分支）
git log --graph --oneline --all
```

### 3.2 过滤和搜索

```bash
# 查看指定作者的提交
git log --author="作者名"

# 查看指定日期范围的提交
git log --since="2024-01-01" --until="2024-12-31"

# 查看最近 N 天的提交
git log --since="7 days ago"

# 查看包含指定关键词的提交
git log --grep="关键词"

# 查看修改了指定文件的提交
git log -- <file-path>

# 查看指定文件的每行最后修改信息
git blame <file-path>

# 查看指定文件的每行最后修改信息（显示作者和日期）
git blame -L 10,20 <file-path>  # 只看 10-20 行
```

### 3.3 高级 log 格式

```bash
# 自定义格式（显示哈希、作者、日期、提交信息）
git log --pretty=format:"%h - %an, %ar : %s"

# 常用别名配置
git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit

# 查看每次提交的文件变更
git log --name-status

# 查看每次提交的文件变更（仅文件名）
git log --name-only

# 查看分支合并历史
git log --merges

# 查看非合并提交
git log --no-merges
```

### 3.4 比较提交

```bash
# 查看两个提交之间的差异
git diff <commit1> <commit2>

# 查看两个分支之间的差异
git diff <branch1>..<branch2>

# 查看当前分支与主分支的差异
git diff main...HEAD

# 查看指定提交的详细信息
git show <commit-hash>

# 查看指定提交修改的文件列表
git show --name-only <commit-hash>

# 查看某个文件在指定提交时的内容
git show <commit-hash>:<file-path>
```

---

## 四、远程仓库操作

### 4.1 拉取和推送

```bash
# 拉取远程更新（不合并）
git fetch

# 拉取远程更新（并合并到当前分支）
git pull

# 拉取远程更新（使用 rebase）
git pull --rebase

# 推送到远程仓库
git push

# 首次推送并设置上游分支
git push -u origin <branch-name>

# 推送所有分支
git push --all

# 推送标签
git push --tags

# 强制推送（危险操作，慎用）
git push --force

# 强制推送（更安全，如果远程有新提交会拒绝）
git push --force-with-lease
```

### 4.2 同步和更新

```bash
# 查看本地分支与远程分支的关系
git branch -vv

# 清理本地已删除的远程分支引用
git remote prune origin

# 或者在 fetch 时自动清理
git fetch --prune

# 拉取远程分支并在本地创建同名分支
git checkout --track origin/<branch-name>

# 设置当前分支跟踪远程分支
git branch --set-upstream-to=origin/<branch-name>
```

---

## 五、撤销和回滚

### 5.1 撤销工作区修改

```bash
# 撤销指定文件的修改（恢复到暂存区状态）
git checkout -- <file>

# 撤销指定文件的修改（新语法）
git restore <file>

# 撤销所有文件的修改
git restore .

# 从暂存区移除指定文件（保留工作区修改）
git reset HEAD <file>

# 从暂存区移除指定文件（新语法）
git restore --staged <file>
```

### 5.2 撤销提交

```bash
# 撤销最后一次提交（保留修改到工作区）
git reset HEAD~1

# 撤销最后一次提交（保留修改到暂存区）
git reset --soft HEAD~1

# 撤销最后一次提交（丢弃所有修改，危险操作）
git reset --hard HEAD~1

# 撤销到指定提交
git reset --hard <commit-hash>

# 创建一个新提交来撤销指定提交（推荐，安全）
git revert <commit-hash>

# 撤销合并提交
git revert -m 1 <merge-commit-hash>
```

### 5.3 临时保存修改

```bash
# 暂存当前修改
git stash

# 暂存当前修改（包含未跟踪文件）
git stash -u

# 暂存当前修改并添加描述
git stash save "描述信息"

# 查看 stash 列表
git stash list

# 应用最近的 stash（保留 stash）
git stash apply

# 应用最近的 stash（删除 stash）
git stash pop

# 应用指定的 stash
git stash apply stash@{0}

# 删除指定的 stash
git stash drop stash@{0}

# 清空所有 stash
git stash clear

# 查看 stash 内容
git stash show -p stash@{0}
```

---

## 六、GitHub 操作（使用 gh CLI）

### 6.1 安装和认证

```bash
# macOS 安装
brew install gh

# 登录 GitHub
gh auth login

# 查看认证状态
gh auth status
```

### 6.2 仓库操作

```bash
# 克隆仓库
gh repo clone <owner>/<repo>

# 查看仓库信息
gh repo view

# 在浏览器中打开仓库
gh repo view --web

# Fork 仓库
gh repo fork

# 创建新仓库
gh repo create <repo-name> --public/--private
```

### 6.3 Pull Request 操作

```bash
# 创建 PR
gh pr create

# 创建 PR（指定标题和内容）
gh pr create --title "标题" --body "描述"

# 创建 PR（填充模板）
gh pr create --fill

# 查看 PR 列表
gh pr list

# 查看指定 PR
gh pr view <pr-number>

# 在浏览器中打开 PR
gh pr view <pr-number> --web

# Checkout PR 到本地
gh pr checkout <pr-number>

# 合并 PR
gh pr merge <pr-number>

# 关闭 PR
gh pr close <pr-number>

# 重新打开 PR
gh pr reopen <pr-number>

# 查看 PR 的 diff
gh pr diff <pr-number>

# 查看 PR 的 CI 状态
gh pr checks <pr-number>

# 添加评论
gh pr comment <pr-number> --body "评论内容"

# 批准 PR
gh pr review <pr-number> --approve

# 请求修改
gh pr review <pr-number> --request-changes --body "请求修改的原因"
```

### 6.4 Issue 操作

```bash
# 查看 issue 列表
gh issue list

# 创建 issue
gh issue create

# 创建 issue（指定标题和内容）
gh issue create --title "标题" --body "描述"

# 查看指定 issue
gh issue view <issue-number>

# 关闭 issue
gh issue close <issue-number>

# 重新打开 issue
gh issue reopen <issue-number>

# 添加评论
gh issue comment <issue-number> --body "评论内容"
```

### 6.5 工作流和 Actions

```bash
# 查看 workflow 列表
gh workflow list

# 查看 workflow 运行历史
gh run list

# 查看指定运行的详细信息
gh run view <run-id>

# 查看运行日志
gh run view <run-id> --log

# 重新运行失败的任务
gh run rerun <run-id>

# 取消运行
gh run cancel <run-id>

# 监控运行状态
gh run watch <run-id>
```

---

## 七、常见场景

### 7.1 日常开发流程

```bash
# 1. 更新主分支
git checkout main
git pull

# 2. 创建功能分支
git checkout -b feature/new-feature

# 3. 开发和提交
git add .
git commit -m "feat: 新增功能"

# 4. 推送到远程
git push -u origin feature/new-feature

# 5. 创建 PR
gh pr create --fill

# 6. PR 合并后，删除分支
git checkout main
git pull
git branch -d feature/new-feature
git push origin --delete feature/new-feature
```

### 7.2 解决冲突

```bash
# 1. 拉取最新代码（可能出现冲突）
git pull

# 2. 查看冲突文件
git status

# 3. 手动解决冲突（编辑文件）
vim <conflict-file>

# 4. 标记冲突已解决
git add <conflict-file>

# 5. 完成合并
git commit

# 或者，如果想放弃合并
git merge --abort
```

### 7.3 同步 Fork 的仓库

```bash
# 1. 添加上游仓库
git remote add upstream <original-repo-url>

# 2. 拉取上游更新
git fetch upstream

# 3. 切换到主分支
git checkout main

# 4. 合并上游更新
git merge upstream/main

# 5. 推送到自己的 Fork
git push origin main
```

### 7.4 查看某个功能的提交历史

```bash
# 查看包含关键词的提交
git log --all --grep="关键词"

# 查看修改了指定文件的提交
git log --follow -- <file-path>

# 查看某个功能分支的所有提交
git log main..feature/new-feature

# 查看某个功能分支的提交（仅显示提交信息）
git log --oneline main..feature/new-feature
```

### 7.5 回滚到指定版本

```bash
# 1. 查看提交历史，找到目标版本
git log --oneline

# 2. 创建一个新提交来回滚（推荐，安全）
git revert <commit-hash>

# 3. 或者直接重置到指定版本（危险，会丢失之后的提交）
git reset --hard <commit-hash>

# 4. 如果已经推送到远程，需要强制推送
git push --force-with-lease
```

### 7.6 清理历史记录（慎用）

```bash
# 交互式 rebase，可以修改、合并、删除历史提交
git rebase -i HEAD~3  # 修改最近 3 个提交

# 合并最近 N 个提交
git reset --soft HEAD~N
git commit -m "合并后的提交信息"

# 从历史中删除敏感文件（需要重写历史）
git filter-branch --tree-filter 'rm -f <sensitive-file>' HEAD

# 或使用更现代的工具
git filter-repo --path <sensitive-file> --invert-paths
```

---

## 八、配置和别名

### 8.1 基础配置

```bash
# 设置用户名和邮箱
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# 设置默认编辑器
git config --global core.editor "vim"

# 设置默认分支名
git config --global init.defaultBranch main

# 启用颜色输出
git config --global color.ui auto

# 查看所有配置
git config --list

# 查看指定配置
git config user.name
```

### 8.2 常用别名

```bash
# 设置别名
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.unstage 'reset HEAD --'
git config --global alias.last 'log -1 HEAD'

# 美化的 log 别名
git config --global alias.lg "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"

# 使用别名
git st
git lg
```

### 8.3 .gitignore 配置

常见的 `.gitignore` 模板：

```gitignore
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
venv/
.venv/
*.egg-info/
dist/
build/

# 环境变量
.env
.env.local
.env.*.local

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# macOS
.DS_Store

# 日志
*.log

# 数据库
*.db
*.sqlite3

# Node.js
node_modules/
npm-debug.log
```

---

## 九、故障排查

### 9.1 查看 Git 操作记录

```bash
# 查看所有 Git 操作记录（包括已删除的提交）
git reflog

# 恢复误删的分支或提交
git checkout <commit-hash>
git checkout -b recovered-branch
```

### 9.2 修复常见问题

```bash
# 问题：提交了错误的文件
# 解决：修改最后一次提交
git reset HEAD~1
git add <correct-files>
git commit -m "正确的提交"

# 问题：推送被拒绝
# 解决：先拉取再推送
git pull --rebase
git push

# 问题：.gitignore 不生效
# 解决：清除缓存
git rm -r --cached .
git add .
git commit -m "Update .gitignore"

# 问题：分支名拼错了
# 解决：重命名分支
git branch -m <old-name> <new-name>

# 如果已经推送到远程
git push origin --delete <old-name>
git push -u origin <new-name>
```

---

## 十、最佳实践

### 10.1 提交信息规范

使用约定式提交（Conventional Commits）：

```
<type>(<scope>): <subject>

<body>

<footer>
```

**type 类型：**
- `feat`: 新功能
- `fix`: 修复 bug
- `docs`: 文档更新
- `style`: 代码格式调整（不影响功能）
- `refactor`: 重构（不是新功能，也不是修复 bug）
- `test`: 测试相关
- `chore`: 构建过程或辅助工具的变动

**示例：**

```bash
git commit -m "feat(auth): 新增用户登录功能"
git commit -m "fix(api): 修复用户列表接口返回错误"
git commit -m "docs: 更新 README 安装说明"
```

### 10.2 分支管理策略

**Git Flow 简化版：**

```
main         - 生产环境分支，永远保持可部署
develop      - 开发分支，最新的开发进度
feature/*    - 功能分支，从 develop 创建，完成后合并回 develop
hotfix/*     - 紧急修复分支，从 main 创建，完成后合并到 main 和 develop
```

**工作流程：**

```bash
# 开发新功能
git checkout develop
git pull
git checkout -b feature/new-feature
# ... 开发 ...
git push -u origin feature/new-feature
# 创建 PR 合并到 develop

# 紧急修复
git checkout main
git pull
git checkout -b hotfix/critical-bug
# ... 修复 ...
git push -u origin hotfix/critical-bug
# 创建 PR 合并到 main 和 develop
```

### 10.3 Pull Request 最佳实践

**PR 描述模板：**

```markdown
## 变更说明
简要描述这个 PR 做了什么。

## 变更类型
- [ ] 新功能
- [ ] Bug 修复
- [ ] 文档更新
- [ ] 重构
- [ ] 测试

## 测试
- [ ] 单元测试通过
- [ ] 本地手工测试通过
- [ ] 新增了测试用例

## 相关 Issue
Closes #123

## 截图（如果适用）
```

**代码审查检查点：**
- 代码是否符合团队规范？
- 是否有足够的测试覆盖？
- 是否更新了文档？
- 是否有安全风险？
- 性能是否有影响？

---

## 十一、快速参考卡片

### 常用命令速查

```bash
# 状态和差异
git status                    # 查看状态
git diff                      # 查看未暂存的修改
git diff --staged             # 查看已暂存的修改

# 暂存和提交
git add .                     # 暂存所有修改
git commit -m "message"       # 提交
git commit --amend            # 修改上一次提交

# 分支
git branch                    # 查看分支
git checkout -b <branch>      # 创建并切换分支
git merge <branch>            # 合并分支
git branch -d <branch>        # 删除分支

# 历史
git log --oneline             # 查看提交历史（简洁）
git log --graph --all         # 查看分支图
git show <commit>             # 查看提交详情

# 远程
git pull                      # 拉取并合并
git push                      # 推送
git push -u origin <branch>   # 首次推送并设置上游

# 撤销
git restore <file>            # 撤销工作区修改
git restore --staged <file>   # 从暂存区移除
git reset HEAD~1              # 撤销最后一次提交
git revert <commit>           # 创建新提交来撤销

# 临时保存
git stash                     # 暂存修改
git stash pop                 # 恢复暂存
git stash list                # 查看暂存列表
```

### gh CLI 速查

```bash
# PR
gh pr create --fill           # 创建 PR
gh pr list                    # 查看 PR 列表
gh pr checkout <number>       # Checkout PR
gh pr merge <number>          # 合并 PR

# Issue
gh issue create               # 创建 issue
gh issue list                 # 查看 issue 列表
gh issue close <number>       # 关闭 issue

# Repo
gh repo view --web            # 在浏览器打开仓库
gh repo clone <owner>/<repo>  # 克隆仓库
```
