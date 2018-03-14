---
layout:     post
title:      "docker在线实验平台一"
subtitle:   "docker在线实验平台一"
date:       2018-03-14 8:00:00
author:     "julyerr"
header-img: "img/projects/pwd/pwd.png"
header-mask: 0.5
catalog:    true
tags:
    - projects
    - flask
---


>这篇blog主要总结2017年暑假使用flask搭建的选课系统，也是整个projects的前台业务逻辑。

![](/img/projects/pwd/whole-arch.png)

本项目主要实现的功能分为老师和学生两块，老师这块主要是在线实验文档的编写以及实验课程、实验内容管理等;学生这块主要是在线完成老师布置的实验任务。<br>

虽然现在选择方向是java后端研发，兴趣广泛，还是挺喜欢python开发的快速哈。flask应用也是基于mvc架构，我们下面分别mvc三个方面分析一下具体的实现，整体上来说还是比较简单的。其中部分涉及到和后台docker的交互方面可以忽略，后台这部分相对复杂一点（使用go处理逻辑较多，笔者现在忙于java后台开发准备中，因此可能在使用到go的时候再进行总结吧，本文可以当作flask的学习demo)。



### 数据库层

![](/img/projects/pwd/flask-relations.png)

一名老师可以开设多门课程，每门课程可有多名学生参加，每名学生同时可以选择多门课程，一门课程可有有多门实验。<br>

alchemy是python实现的功能比较强大的orm，只需要定义好模型，然后调用命令`db.create_all()`就能自动为我们创建好数据表。下面是对应的models.py文件.虽然老师和学生的列名基本相同，但是为了后面操作方便（外键约束等）还是考虑分成两个表进行管理。


```python
class Teacher(UserMixin, db.Model):
    __tablename__ = 'teachers'

    # 列名
    name = db.Column(db.String(60), primary_key=True)
    realname = db.Column(db.String(30), nullable=False)
    password_hash = db.Column(db.String(128), nullable=False)
    isTeacher = db.Column(db.Boolean(), nullable=False, default=True)
    # 方便获取courses对象
    courses = db.relationship('Course', backref='teachers',
                              lazy='dynamic')

    @property
    def password(self):
        """
        Prevent pasword from being accessed
        """
        raise AttributeError('password is not a readable attribute.')

    @password.setter
    def password(self, password):
        """
        Set password to a hashed password
        """
        self.password_hash = password

    def verifypassword(self, password):
        """
        Check if hashed password matches actual password
        """
        return self.password_hash == password

    def __repr__(self):
        return '<Teacher: {}>'.format(self.username)

        # 用于标志每个用户

    def get_id(self):
        return unicode(self.name)


#     约束表
registrations = db.Table('registrations',
                         db.Column('studentName', db.String(60), db.ForeignKey('students.name')),
                         db.Column('courseNums', db.String(60), db.ForeignKey('courses.courseNums'))
                         )


class Student(UserMixin, db.Model):
    __tablename__ = 'students'

    name = db.Column(db.String(60), nullable=False, primary_key=True)
    realname = db.Column(db.String(30), nullable=False)
    password_hash = db.Column(db.String(128), nullable=False)
    isTeacher = db.Column(db.Boolean(), default=False)
    # 方便获取到courses对象
    courses = db.relationship('Course', secondary=registrations,
                              backref=db.backref('students', lazy='dynamic'),
                              lazy='dynamic')

    @property
    def password(self):
        """
        Prevent pasword from being accessed
        """
        raise AttributeError('password is not a readable attribute.')

    @password.setter
    def password(self, password):
        """
        Set password to a hashed password
        """
        self.password_hash = generate_password_hash(password)

    def verifypassword(self, password):
        """
        Check if hashed password matches actual password
        """
        return check_password_hash(self.password_hash, password)

    def __repr__(self):
        return '<Student: {}>'.format(self.name)

    def get_id(self):
        return unicode(self.name)


# Set up user_loader
@login_manager.user_loader
def load_user(user_id):
    teacher = Teacher.query.filter_by(name=str(user_id)).first()
    if teacher is None:
        return Student.query.filter_by(name=str(user_id)).first()
    return teacher


class Course(db.Model):
    __tablename__ = 'courses'
    courseNums = db.Column(db.String(60), primary_key=True)
    name = db.Column(db.String(60), primary_key=False, nullable=False)
    description = db.Column(db.String(200))
    # 外键约束
    teacherName = db.Column(db.String(60), db.ForeignKey('teachers.name'))
    # 方便获取experiment对象
    experiments = db.relationship('Experiment', backref='courses',
                                  lazy='dynamic')

    def __repr__(self):
        return self.name.encode('utf-8')


def gen_id():
    return uuid.uuid4().hex


class Experiment(db.Model):
    __tablename__ = 'experiments'
    id = db.Column(db.String(60), default=gen_id, primary_key=True)
    name = db.Column(db.String(60))
    description = db.Column(db.String(200))
    content = db.Column(db.LargeBinary)
    # 外键约束
    courseNums = db.Column(db.String(60), db.ForeignKey('courses.courseNums'))
    containerName = db.Column(db.String(60))
    teacherName = db.Column(db.String(60), nullable=False)

    def __repr__(self):
        return '{}'.format(self.name)
```


---
### 路由控制层

#### 用户认证管理

有老师和同学两者角色，使用Flask_Login管理用户认证

```python
# 用户认证管理
login_manager.init_app(app)
login_manager.login_message = "You are not authorised to see this page. Please log in"
# 设置登入url
login_manager.login_view = "auth.login"
```

`auth/views.py`

```python
@auth.route('/', methods=['GET', 'POST'])
def login():
    # 该用户是否已经登入
    if 'user_id' in session.keys():
        if current_user.isTeacher:
            return redirect(url_for('admin.list_courses'))
        else:
            return redirect(url_for('home.list_courses'))
    form = LoginForm()
    if form.validate_on_submit():
        if form.is_teacher.data:
            # 密码验证
            teacher = Teacher.query.filter_by(name=form.name.data).first()
            if teacher is not None and teacher.verifypassword(
                    form.password.data):
                # 设置当前活跃用户以及在session中设置user_id
                login_user(teacher)
                return redirect(url_for('home.teacher_dashboard'))
            else:
                flash(u'密码不正确')

        else:
            student = Student.query.filter_by(name=form.name.data).first()
            if student is not None and student.verifypassword(
                    form.password.data):
                login_user(student)
                return redirect(url_for('home.list_courses'))
            else:
                flash(u'密码不正确')
    return render_template('auth/login.html', form=form)

@auth.route('/logout')
@login_required
def logout():
    """
    Handle requests to the /logout route
    Log an employee out through the logout link
    """
    logout_user()
    # flash('You have successfully been logged out.')

    # redirect to the login page
    return redirect(url_for('auth.login'))    
```

老师和同学的权限设置是通过路由前缀设置的

```python
from app import models

from .admin import admin as admin_blueprint
app.register_blueprint(admin_blueprint, url_prefix='/admin')

from .auth import auth as auth_blueprint
app.register_blueprint(auth_blueprint)

from .home import home as home_blueprint
app.register_blueprint(home_blueprint)
下代码中只需要设置

```

@login_required就能判断用户是否登入,结合如下就能区分不同用户

```python
if not current_user.isTeacher:
    abort(403)
```


#### 不同业务逻辑处理

flask提供了Flask-WTF这个库，比较方便的实现了表单信息的定制

```python
# 注册表单
class RegistrationForm(FlaskForm):
    name = StringField(u'学号', validators=[DataRequired()])
    realname = StringField(u'姓名', validators=[DataRequired()])
    password = PasswordField(u'密码', validators=[DataRequired()])
    submit = SubmitField(u'注册')

    # 调用验证执行的方法
    def validate_username(self, field):
        if Student.query.filter_by(name=field.data).first() or Teacher.filter_by(name=field.name).first:
            raise ValidationError('Username is already in use.')

# 其他登入、实验类似，比较有特色的是老师文档编写的表单

#     文档编辑的表单，具体参见CKEditor相关的使用说明
class CKEditor(object):
    def __init__(self):
        pass

    def gen_rnd_filename(self):
        """generate a random filename"""
        filename_prefix = datetime.datetime.now().strftime("%Y%m%d%H%M%S")
        return "%s%s" % (filename_prefix, str(random.randrange(1000, 10000)))

    def upload(self, endpoint=current_app):
        """img or file upload methods"""
        error = ''
        url = ''
        callback = request.args.get("CKEditorFuncNum")

        # 文件保存
        if request.method == 'POST' and 'upload' in request.files:
            # /static/upload
            fileobj = request.files['upload']
            fname, fext = os.path.splitext(fileobj.filename)
            rnd_name = '%s%s' % (self.gen_rnd_filename(), fext)
            filepath = os.path.join(endpoint.static_folder, 'upload', rnd_name)

            dirname = os.path.dirname(filepath)
            if not os.path.exists(dirname):
                try:
                    os.makedirs(dirname)
                except:
                    error = 'ERROR_CREATE_DIR'
            elif not os.access(dirname, os.W_OK):
                    error = 'ERROR_DIR_NOT_WRITEABLE'
            if not error:
                fileobj.save(filepath)
                url = url_for('admin.static', filename='%s/%s' % ('upload', rnd_name))
        else:
            error = 'post error'

        res = """
                <script type="text/javascript">
                window.parent.CKEDITOR.tools.callFunction(%s, '%s', '%s');
                </script>
             """ % (callback, url, error)

        response = make_response(res)
        response.headers["Content-Type"] = "text/html"
        return response
```

#### 学生逻辑处理

相对简单一点<br>


**个人信息修改**

```python
@home.route('/update_infos', methods=['GET', 'POST'])
@login_required
def update_infos():
    form = UpdateForm()
    if form.validate_on_submit():
        student = Student.query.filter_by(name=current_user.name).first()
        student.realname = form.realname.data
        student.password_hash = generate_password_hash(form.password.data)
        db.session.commit()
        db.session.close()
        # 登出
        logout_user()
        return redirect(url_for('auth.login'))
    return render_template('home/update_infos.html', name=current_user.realname, form=form)
```

**选课**

```python
@home.route('/selectCourse', methods=['GET', 'POST'])
@login_required
def selectCourse():  # 查询表单提交处理函数
    nums = request.form['nums']
    course = Course.query.filter_by(courseNums=nums).first()
    if course:
        try:
        # 通过课程的courseNums添加选课记录
            current_user.courses.append(course)
            # 提交事务
            db.session.commit()
            flash(u'选课成功')
            return redirect(url_for('home.list_courses'))
        except:
            flash(u'选课失败，可能是您已经拥有该门课程')
            return redirect(url_for('home.list_courses'))
    else:
        flash(u'选课码无效')
        return redirect(url_for('home.selectCourseForm'))
```

老师在增加一门课程的时候，系统自动为该课程设置一个uuid;然后学生只需要获取到uuid，在选课系统中输入就能选到这门课程，避免了录入学生的工作。整个数据库，老师的信息需要手动录入，学生可以通过注册界面录入系统。<br>

**显示课程**

```python
@home.route('/list_courses', methods=['GET', 'POST'])
@login_required
def list_courses():
    courses = Student.query.filter_by(name=current_user.name).first().courses
    experimentSet = []
    for i in courses:
        experiments = Experiment.query.filter_by(courseNums=i.courseNums).all()
        experimentSet.append(experiments)
    #     重定向课程显示界面
    sessions = Session.query.filter_by(name=current_user.realname).all()
    return render_template('home/list_courses.html', courses=courses, experimentSet=experimentSet,
                           name=current_user.realname,sessions=sessions,isTeacher="student",ip=PWD_IP)
```

html文件看起来还是挺容易理解的，不过得有模板技术的基础（模板继承、扩展、参数传入等）

---
#### 老师这块的业务逻辑

**添加实验**

```python
@admin.route('/experiments/add', methods=['GET', 'POST'])
@login_required
def add_experiment():
    if not current_user.isTeacher:
        abort(403)
    """
    Add a experiment
    """

    add_experiment = True

    form = ExperimentForm()
    if form.validate_on_submit():
        experiment = Experiment(name=form.name.data,description=form.description.data,
                    content=form.content.data,courseNums=form.courseNums.data.courseNums,
                    containerName=form.containerName.data, teacherName=current_user.name)  # .name)
        try:
            db.session.add(experiment)
            db.session.commit()
            flash(u'实验创建完成')
        except:
            flash(u'实验创建失败')
            return redirect(url_for('admin.add_experiment'))
            

        # redirect to the experiments page
        return redirect(url_for('admin.list_experiments'))

    return render_template('admin/experiments/experiment.html', add_experiment=add_experiment,
                           form=form, title="Add experiment",name=current_user.name,isTeacher="teacher")
```

修改实验等操作代码类似<br>

**添加课程**

```python
@admin.route('/courses/add', methods=['GET', 'POST'])
@login_required
def add_course():
    if not current_user.isTeacher:
        abort(403)    
    add_course = True
    courseNums = ''.join(random.sample(string.ascii_letters+string.digits, 8))
    form = CourseForm()
    if form.validate_on_submit():
        course = Course(name=form.name.data,
                                description=form.description.data,teacherName=current_user.name,
                                courseNums=form.courseNums.data)
        try:
            # add course to the database
            db.session.add(course)
            db.session.commit()
            flash(u'成功创建一门课程')
        except:
            # in case course name already exists
            flash(u'创建课程失败，可能是选课口令与已存在的课程相同')

        # redirect to courses page
        return redirect(url_for('admin.list_courses'))

    # load course template
    return render_template('admin/courses/course.html',
                           add_course=add_course, form=form,
                           title="Add Course", code=courseNums)
```

添加修改课程代码类似


---
### 让代码运行起来

上面只是大致介绍了整个选课的逻辑以及涉及到的技术，其实项目代码只有自己慢慢去分析去实践才会有较好的学习效果。<br>


作为了一名合格的后台开发人员，电脑上应该装好一些常用的软件和工具,下面以ubuntu系统为例

- 首先安装好mysql服务器，建立好step1数据库（也可以自定义名称，然后在config.py中进行配置）

```shell
# 中间会有用户名和密码设置
sudo apt-get install mariadb-server libmysqld-dev git -y;
sudo systemctl start mysqld && mysql -uroot -p;
create database step1;
```

- 安装好python开发环境，推荐使用virtualenv配置虚拟环境。

```shell
sudo apt-get install virtualenv -y 
virtualenv env && . env/bin/activate
```

- 一些项目的python依赖包

```shell
pip install -r requirementx.txt 
```

- clone项目并配置

```shell
git clone https://github.com/julyerr/font.git
#编辑mysql配置文件config.py

export FLASK_CONFIG=development 
python run.py db migrate && python run.py db upgrade
```

- 数据库中初始化数据导入并运行项目

```shell
mysql -uroot -p 
use step1 
insert into teachers values('teacher1','teacher1',teacher1',True); 
python run.py runserver -h 0.0.0.0
```

---
### 参考资料
- [font](https://github.com/julyerr/font)
- [mysql_config not found](https://stackoverflow.com/questions/5178292/pip-install-mysql-python-fails-with-environmenterror-mysql-config-not-found)
- [too many values to unpack (expected 2)](https://segmentfault.com/q/1010000012712132)
