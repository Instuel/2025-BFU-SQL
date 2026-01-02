<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>用户与角色管理</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/common.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/components.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/biz/rbac.css">
</head>
<body>
    <div class="rbac-container">
        <div class="page-header">
            <h1 class="page-title">用户与角色管理</h1>
            <p class="page-subtitle">维护账号信息，分配角色权限（RBAC），设置运维人员的负责区域</p>
        </div>

        <div class="tabs">
            <button class="tab-btn active" onclick="switchTab('users')">用户管理</button>
            <button class="tab-btn" onclick="switchTab('roles')">角色管理</button>
            <button class="tab-btn" onclick="switchTab('permissions')">权限配置</button>
        </div>

        <div id="users-card" class="content-card active">
            <div class="toolbar">
                <div class="search-box">
                    <input type="text" class="search-input" id="userSearch" placeholder="搜索用户名、姓名、工号...">
                    <button class="btn btn-primary" onclick="searchUsers()">搜索</button>
                </div>
                <button class="btn btn-success" onclick="openUserModal()">+ 新增用户</button>
            </div>

            <table class="data-table">
                <thead>
                    <tr>
                        <th>工号</th>
                        <th>用户名</th>
                        <th>姓名</th>
                        <th>角色</th>
                        <th>负责区域</th>
                        <th>状态</th>
                        <th>操作</th>
                    </tr>
                </thead>
                <tbody id="userTableBody">
                </tbody>
            </table>

            <div class="pagination" id="userPagination">
            </div>
        </div>

        <div id="roles-card" class="content-card">
            <div class="toolbar">
                <div class="search-box">
                    <input type="text" class="search-input" id="roleSearch" placeholder="搜索角色名称、描述...">
                    <button class="btn btn-primary" onclick="searchRoles()">搜索</button>
                </div>
                <button class="btn btn-success" onclick="openRoleModal()">+ 新增角色</button>
            </div>

            <table class="data-table">
                <thead>
                    <tr>
                        <th>角色标识</th>
                        <th>角色名称</th>
                        <th>权限等级</th>
                        <th>用户数量</th>
                        <th>状态</th>
                        <th>操作</th>
                    </tr>
                </thead>
                <tbody id="roleTableBody">
                </tbody>
            </table>

            <div class="pagination" id="rolePagination">
            </div>
        </div>

        <div id="permissions-card" class="content-card">
            <div class="toolbar">
                <h3>权限配置</h3>
            </div>

            <table class="data-table">
                <thead>
                    <tr>
                        <th>权限名称</th>
                        <th>权限标识</th>
                        <th>描述</th>
                        <th>关联角色</th>
                    </tr>
                </thead>
                <tbody id="permissionTableBody">
                </tbody>
            </table>
        </div>
    </div>

    <div class="modal-overlay" id="userModal">
        <div class="modal">
            <div class="modal-header">
                <h3 class="modal-title" id="userModalTitle">新增用户</h3>
                <button class="modal-close" onclick="closeUserModal()">&times;</button>
            </div>
            <form id="userForm">
                <input type="hidden" id="userId">
                <div class="form-group">
                    <label class="form-label">工号 *</label>
                    <input type="text" class="form-input" id="userEmployeeId" required>
                </div>
                <div class="form-group">
                    <label class="form-label">用户名 *</label>
                    <input type="text" class="form-input" id="username" required>
                </div>
                <div class="form-group">
                    <label class="form-label">姓名 *</label>
                    <input type="text" class="form-input" id="userRealName" required>
                </div>
                <div class="form-group">
                    <label class="form-label">密码 *</label>
                    <input type="password" class="form-input" id="userPassword" required>
                </div>
                <div class="form-group">
                    <label class="form-label">角色 *</label>
                    <select class="form-select" id="userRole" required>
                        <option value="">请选择角色</option>
                    </select>
                </div>
                <div class="form-group">
                    <label class="form-label">负责区域</label>
                    <select class="form-select" id="userArea">
                        <option value="">请选择区域</option>
                        <option value="A区">A区</option>
                        <option value="B区">B区</option>
                        <option value="C区">C区</option>
                        <option value="全厂">全厂</option>
                    </select>
                </div>
                <div class="form-group">
                    <label class="form-label">状态</label>
                    <select class="form-select" id="userStatus">
                        <option value="active">启用</option>
                        <option value="inactive">禁用</option>
                    </select>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" onclick="closeUserModal()">取消</button>
                    <button type="submit" class="btn btn-primary">保存</button>
                </div>
            </form>
        </div>
    </div>

    <div class="modal-overlay" id="roleModal">
        <div class="modal">
            <div class="modal-header">
                <h3 class="modal-title" id="roleModalTitle">新增角色</h3>
                <button class="modal-close" onclick="closeRoleModal()">&times;</button>
            </div>
            <form id="roleForm">
                <input type="hidden" id="roleId">
                <div class="form-group">
                    <label class="form-label">角色标识 *</label>
                    <input type="text" class="form-input" id="roleCode" required>
                </div>
                <div class="form-group">
                    <label class="form-label">角色名称 *</label>
                    <input type="text" class="form-input" id="roleName" required>
                </div>
                <div class="form-group">
                    <label class="form-label">权限等级 *</label>
                    <select class="form-select" id="roleLevel" required>
                        <option value="1">Level 1 - 运维人员</option>
                        <option value="2">Level 2 - 数据分析师</option>
                        <option value="3">Level 3 - 能源管理员</option>
                        <option value="4">Level 4 - 企业管理层</option>
                        <option value="5">Level 5 - 系统管理员</option>
                    </select>
                </div>
                <div class="form-group">
                    <label class="form-label">权限</label>
                    <div class="checkbox-group" id="rolePermissions">
                    </div>
                </div>
                <div class="form-group">
                    <label class="form-label">状态</label>
                    <select class="form-select" id="roleStatus">
                        <option value="active">启用</option>
                        <option value="inactive">禁用</option>
                    </select>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" onclick="closeRoleModal()">取消</button>
                    <button type="submit" class="btn btn-primary">保存</button>
                </div>
            </form>
        </div>
    </div>

    <script>
        let currentPage = 1;
        let pageSize = 10;

        function switchTab(tab) {
            document.querySelectorAll('.tab-btn').forEach(btn => btn.classList.remove('active'));
            document.querySelectorAll('.content-card').forEach(card => card.classList.remove('active'));

            event.target.classList.add('active');
            document.getElementById(tab + '-card').classList.add('active');

            if (tab === 'users') {
                loadUsers();
            } else if (tab === 'roles') {
                loadRoles();
            } else if (tab === 'permissions') {
                loadPermissions();
            }
        }

        var contextPath = '${pageContext.request.contextPath}';

        function loadUsers() {
            var search = document.getElementById('userSearch').value;
            fetch(contextPath + '/api/admin/users?page=' + currentPage + '&size=' + pageSize + '&search=' + encodeURIComponent(search))
                .then(function(response) { return response.json(); })
                .then(function(data) {
                    if (data.success) {
                        renderUsers(data.data.list);
                        renderPagination('userPagination', data.data.total, data.data.page, data.data.size);
                    }
                })
                .catch(function(error) { console.error('加载用户列表失败:', error); });
        }

        function renderUsers(users) {
            var tbody = document.getElementById('userTableBody');
            var html = '';
            for (var i = 0; i < users.length; i++) {
                var user = users[i];
                var statusBadge = user.status === 'active' ? '启用' : '禁用';
                html += '<tr>' +
                    '<td>' + user.employeeId + '</td>' +
                    '<td>' + (user.loginAccount || user.username || '') + '</td>' +
                    '<td>' + user.realName + '</td>' +
                    '<td>' + user.roleName + '</td>' +
                    '<td>' + (user.area || '-') + '</td>' +
                    '<td><span class="status-badge ' + user.status + '">' + statusBadge + '</span></td>' +
                    '<td><div class="action-buttons">' +
                    '<button class="action-btn edit" onclick="editUser(' + user.id + ')">编辑</button>' +
                    '<button class="action-btn delete" onclick="deleteUser(' + user.id + ')">删除</button>' +
                    '</div></td></tr>';
            }
            tbody.innerHTML = html;
        }

        function loadRoles() {
            var search = document.getElementById('roleSearch').value;
            fetch(contextPath + '/api/admin/roles?page=' + currentPage + '&size=' + pageSize + '&search=' + encodeURIComponent(search))
                .then(function(response) { return response.json(); })
                .then(function(data) {
                    if (data.success) {
                        renderRoles(data.data.list);
                        renderPagination('rolePagination', data.data.total, data.data.page, data.data.size);
                    }
                })
                .catch(function(error) { console.error('加载角色列表失败:', error); });
        }

        function renderRoles(roles) {
            var tbody = document.getElementById('roleTableBody');
            var html = '';
            for (var i = 0; i < roles.length; i++) {
                var role = roles[i];
                var statusBadge = role.status === 'active' ? '启用' : '禁用';
                html += '<tr>' +
                    '<td>' + role.code + '</td>' +
                    '<td>' + role.name + '</td>' +
                    '<td>Level ' + role.level + '</td>' +
                    '<td>' + role.userCount + '</td>' +
                    '<td><span class="status-badge ' + role.status + '">' + statusBadge + '</span></td>' +
                    '<td><div class="action-buttons">' +
                    '<button class="action-btn edit" onclick="editRole(' + role.id + ')">编辑</button>' +
                    '<button class="action-btn delete" onclick="deleteRole(' + role.id + ')">删除</button>' +
                    '</div></td></tr>';
            }
            tbody.innerHTML = html;
        }

        function loadPermissions() {
            fetch(contextPath + '/api/admin/permissions')
                .then(function(response) { return response.json(); })
                .then(function(data) {
                    if (data.success) {
                        renderPermissions(data.data);
                    }
                })
                .catch(function(error) { console.error('加载权限列表失败:', error); });
        }

        function renderPermissions(permissions) {
            var tbody = document.getElementById('permissionTableBody');
            var html = '';
            for (var i = 0; i < permissions.length; i++) {
                var perm = permissions[i];
                html += '<tr>' +
                    '<td>' + perm.name + '</td>' +
                    '<td>' + perm.code + '</td>' +
                    '<td>' + perm.description + '</td>' +
                    '<td>' + perm.roles.join(', ') + '</td>' +
                    '</tr>';
            }
            tbody.innerHTML = html;
        }

        function openUserModal(userId) {
            document.getElementById('userModal').classList.add('active');
            document.getElementById('userForm').reset();
            document.getElementById('userId').value = '';
            document.getElementById('userModalTitle').textContent = userId ? '编辑用户' : '新增用户';
            
            loadRolesForSelect();
        }

        function closeUserModal() {
            document.getElementById('userModal').classList.remove('active');
        }

        function editUser(userId) {
            fetch(contextPath + '/api/admin/users/' + userId)
                .then(function(response) { return response.json(); })
                .then(function(data) {
                    if (data.success) {
                        var user = data.data;
                        document.getElementById('userId').value = user.id;
                        document.getElementById('userEmployeeId').value = user.employeeId;
                        document.getElementById('username').value = user.loginAccount || user.username;
                        document.getElementById('userRealName').value = user.realName;
                        document.getElementById('userPassword').value = user.password;
                        document.getElementById('userRole').value = user.roleId;
                        document.getElementById('userArea').value = user.area;
                        document.getElementById('userStatus').value = user.status;
                        
                        openUserModal(userId);
                    }
                })
                .catch(function(error) { console.error('加载用户信息失败:', error); });
        }

        function deleteUser(userId) {
            if (confirm('确定要删除该用户吗？')) {
                fetch(contextPath + '/api/admin/users/' + userId, {
                    method: 'DELETE'
                })
                .then(function(response) { return response.json(); })
                .then(function(data) {
                    if (data.success) {
                        alert('删除成功！');
                        loadUsers();
                    } else {
                        alert('删除失败：' + data.message);
                    }
                })
                .catch(function(error) {
                    console.error('删除用户失败:', error);
                    alert('删除失败：' + error.message);
                });
            }
        }

        function openRoleModal(roleId) {
            document.getElementById('roleModal').classList.add('active');
            document.getElementById('roleForm').reset();
            document.getElementById('roleId').value = '';
            document.getElementById('roleModalTitle').textContent = roleId ? '编辑角色' : '新增角色';
            
            loadPermissionsForCheckbox();
        }

        function closeRoleModal() {
            document.getElementById('roleModal').classList.remove('active');
        }

        function editRole(roleId) {
            fetch(contextPath + '/api/admin/roles/' + roleId)
                .then(function(response) { return response.json(); })
                .then(function(data) {
                    if (data.success) {
                        var role = data.data;
                        document.getElementById('roleId').value = role.id;
                        document.getElementById('roleCode').value = role.code;
                        document.getElementById('roleName').value = role.name;
                        document.getElementById('roleLevel').value = role.level;
                        document.getElementById('roleStatus').value = role.status;
                        
                        role.permissions.forEach(function(permId) {
                            var checkbox = document.getElementById('perm_' + permId);
                            if (checkbox) checkbox.checked = true;
                        });
                        
                        openRoleModal(roleId);
                    }
                })
                .catch(error => console.error('加载角色信息失败:', error));
        }

        function deleteRole(roleId) {
            if (confirm('确定要删除该角色吗？')) {
                fetch(`${pageContext.request.contextPath}/api/admin/roles/${roleId}`, {
                    method: 'DELETE'
                })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        alert('删除成功！');
                        loadRoles();
                    } else {
                        alert('删除失败：' + data.message);
                    }
                })
                .catch(error => {
                    console.error('删除角色失败:', error);
                    alert('删除失败：' + error.message);
                });
            }
        }

        function loadRolesForSelect() {
            fetch(`${pageContext.request.contextPath}/api/admin/roles/all`)
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        const select = document.getElementById('userRole');
                        select.innerHTML = '<option value="">请选择角色</option>';
                        data.data.forEach(role => {
                            select.innerHTML += `<option value="${role.id}">${role.name}</option>`;
                        });
                    }
                })
                .catch(error => console.error('加载角色列表失败:', error));
        }

        function loadPermissionsForCheckbox() {
            fetch(`${pageContext.request.contextPath}/api/admin/permissions`)
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        const container = document.getElementById('rolePermissions');
                        container.innerHTML = data.data.map(perm => `
                            <label class="checkbox-item">
                                <input type="checkbox" id="perm_${perm.id}" value="${perm.id}">
                                ${perm.name}
                            </label>
                        `).join('');
                    }
                })
                .catch(error => console.error('加载权限列表失败:', error));
        }

        function renderPagination(containerId, total, page, size) {
            const totalPages = Math.ceil(total / size);
            const container = document.getElementById(containerId);
            
            let html = '';
            
            html += `<button class="page-btn" onclick="changePage(${page - 1})" ${page === 1 ? 'disabled' : ''}>上一页</button>`;
            
            for (let i = 1; i <= totalPages; i++) {
                html += `<button class="page-btn ${i === page ? 'active' : ''}" onclick="changePage(${i})">${i}</button>`;
            }
            
            html += `<button class="page-btn" onclick="changePage(${page + 1})" ${page === totalPages ? 'disabled' : ''}>下一页</button>`;
            
            container.innerHTML = html;
        }

        function changePage(page) {
            currentPage = page;
            loadUsers();
        }

        function searchUsers() {
            currentPage = 1;
            loadUsers();
        }

        function searchRoles() {
            currentPage = 1;
            loadRoles();
        }

        document.getElementById('userForm').addEventListener('submit', function(e) {
            e.preventDefault();
            
            const userId = document.getElementById('userId').value;
            const userData = {
                employeeId: document.getElementById('userEmployeeId').value,
                username: document.getElementById('username').value,
                realName: document.getElementById('userRealName').value,
                password: document.getElementById('userPassword').value,
                roleId: document.getElementById('userRole').value,
                area: document.getElementById('userArea').value,
                status: document.getElementById('userStatus').value
            };

            const url = userId ? `${pageContext.request.contextPath}/api/admin/users/${userId}` : `${pageContext.request.contextPath}/api/admin/users`;
            const method = userId ? 'PUT' : 'POST';

            fetch(url, {
                method: method,
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(userData)
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert('保存成功！');
                    closeUserModal();
                    loadUsers();
                } else {
                    alert('保存失败：' + data.message);
                }
            })
            .catch(error => {
                console.error('保存用户失败:', error);
                alert('保存失败：' + error.message);
            });
        });

        document.getElementById('roleForm').addEventListener('submit', function(e) {
            e.preventDefault();
            
            const roleId = document.getElementById('roleId').value;
            const selectedPermissions = [];
            document.querySelectorAll('#rolePermissions input[type="checkbox"]:checked').forEach(checkbox => {
                selectedPermissions.push(checkbox.value);
            });

            const roleData = {
                code: document.getElementById('roleCode').value,
                name: document.getElementById('roleName').value,
                level: document.getElementById('roleLevel').value,
                permissions: selectedPermissions,
                status: document.getElementById('roleStatus').value
            };

            const url = roleId ? `${pageContext.request.contextPath}/api/admin/roles/${roleId}` : `${pageContext.request.contextPath}/api/admin/roles`;
            const method = roleId ? 'PUT' : 'POST';

            fetch(url, {
                method: method,
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(roleData)
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert('保存成功！');
                    closeRoleModal();
                    loadRoles();
                } else {
                    alert('保存失败：' + data.message);
                }
            })
            .catch(error => {
                console.error('保存角色失败:', error);
                alert('保存失败：' + error.message);
            });
        });

        window.onload = function() {
            loadUsers();
        };
    </script>
</body>
</html>
