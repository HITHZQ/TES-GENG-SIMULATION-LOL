%% TES 超音速旋转陀螺仿真：全功能终极整合版
% 特性：1. 自动载入STL 2. 0-4396加速 3. 右侧图例补全 4. 视频保存
clear; clc; close all;

%% 1. 环境与模型载入 (核心：定义 faces 和 vertices)
filename = 'TES_Helmet_Gyro.stl';

if ~exist(filename, 'file')
    error('找不到 STL 文件，请确保文件在当前文件夹内。');
end

try
    % 读取 STL 获取顶点和面
    model = stlread(filename);
    vertices = model.Points;
    faces = model.ConnectivityList;
catch
    [faces, vertices] = stlread(filename); 
end

% 归一化中心：确保自转轴心在 Z 轴
vertices(:,1) = vertices(:,1) - (max(vertices(:,1)) + min(vertices(:,1)))/2;
vertices(:,2) = vertices(:,2) - (max(vertices(:,2)) + min(vertices(:,2)))/2;

fprintf('模型成功识别：顶点 %d, 面 %d\n', size(vertices, 1), size(faces, 1));

%% 2. 物理与压力场计算 (为云图准备模板)
gamma = 1.4; P_inf = 101325; rho_inf = 1.225; a_inf = 343;
r_vert = sqrt(vertices(:,1).^2 + vertices(:,2).^2);
R_max = max(r_vert);
target_rpm = 4396;
omega_target = (target_rpm * 2 * pi) / 60; 

% 预计算 4396 RPM 时的压力分布模板
M_template = (omega_target * r_vert) / a_inf;
P_template = P_inf * (1 + (gamma-1)/2 * M_template.^2).^(gamma/(gamma-1));
Cp_template = (P_template - P_inf) / (0.5 * rho_inf * a_inf^2);

%% 3. 场景渲染与图例布局 (修复"缺少右侧图例"的关键)
% 稍微加宽窗口 (1200像素)，为右侧留出空间
fig = figure('Color', [0.05 0.05 0.05], 'Position', [50 50 1200 800], 'Name', 'TES Gyro 4396');
hold on;

% 创建图组并限制绘图区宽度，防止 Colorbar 挤压模型
ax = gca;
set(ax, 'OuterPosition', [0 0 0.85 1]); % 核心：绘图区只占左侧 85%

% 初始渲染陀螺
h_gyro = patch('Faces', faces, 'Vertices', vertices, ...
               'FaceVertexCData', zeros(size(vertices,1),1), ...
               'FaceColor', 'interp', 'EdgeColor', 'none', ...
               'FaceLighting', 'gouraud', 'BackFaceLighting', 'reverselit', ...
               'SpecularStrength', 0.8, 'DiffuseStrength', 0.6, 'AmbientStrength', 0.3);

% 设置 TES 风格色带：黑 -> 红 -> 白
tes_colors = [0 0 0; 0.5 0 0; 1 0 0; 1 1 1];
colormap(interp1(linspace(0,1,4), tes_colors, linspace(0,1,256)));

% --- 显式创建并美化右侧图例 ---
cb = colorbar('EastOutside'); 
cb.Color = 'w';              
cb.Label.String = '压力系数 (Pressure Coefficient Cp)';
cb.Label.FontSize = 11;
cb.Label.FontWeight = 'bold';
caxis([0 max(Cp_template)]); % 固定刻度范围，防止颜色闪烁

% 视角与灯光
view(35, 20); axis equal; axis off;
camlight('headlight'); lighting gouraud; material shiny;
t_h = title('TES 陀螺：准备启动...', 'Color', 'w', 'FontSize', 16);

%% 4. 视频录制准备
video_name = 'TES_Gyro_4396_Final.mp4';
v = VideoWriter(video_name, 'MPEG-4');
v.FrameRate = 30;
open(v);

%% 5. 动画录制循环
n_frames = 150; 
V_orig = vertices;
current_angle = 0;

fprintf('开始录制视频，包含右侧图例展示...\n');

for i = 1:n_frames
    % 加速逻辑
    t = i / n_frames; 
    current_rpm = target_rpm * (sin(t * pi/2)); 
    step_size = (current_rpm * 360) / (60 * v.FrameRate); 
    current_angle = current_angle + step_size;
    
    % 更新压力颜色 (Cp 随转速平方增长)
    current_Cp = Cp_template * ((current_rpm / target_rpm)^2);
    
    % 旋转矩阵应用
    angle_rad = deg2rad(current_angle);
    Rz = [cos(angle_rad), -sin(angle_rad), 0; sin(angle_rad), cos(angle_rad), 0; 0, 0, 1];
    h_gyro.Vertices = (Rz * V_orig')';
    h_gyro.FaceVertexCData = current_Cp;
    
    % 刷新标题文本
    set(t_h, 'String', sprintf('TES 启动仿真 | 实时转速: %.0f RPM | 搏至无憾', current_rpm));
    
    if i == n_frames
        set(t_h, 'Color', [1 0.84 0], 'String', '4396 RPM 目标达成！');
    end
    
    drawnow limitrate;
    
    % --- 关键：使用 getframe(fig) 捕捉整个窗口，包含图例 ---
    frame = getframe(fig); 
    writeVideo(v, frame);
end

close(v);
fprintf('视频已保存：当前文件夹 -> %s\n', video_name);