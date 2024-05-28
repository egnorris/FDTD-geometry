#import Pkg
#Pkg.add("GLMakie")
#Pkg.add("JSON")
using GLMakie
using JSON


function load_JSON(;geometry_filepath="geometry.json", config_filepath="configuration.json")
    return [open(JSON.parse, geometry_filepath), open(JSON.parse, config_filepath)]
end
    

function get_vertices(x1_coordinate_slider, x2_coordinate_slider, plane, L, W, T, R, shape)
    if shape == "Rectangle"
        return rectangle_vertices(x1_coordinate_slider, x2_coordinate_slider, plane, L, W, T)
    elseif shape == "Triangle"
        if plane == "xz"
            #triangles have to be placed with face in the xz plane
            return triangle_vertices(x1_coordinate_slider, x2_coordinate_slider, W, L)
        else
            return rectangle_vertices(x1_coordinate_slider, x2_coordinate_slider, plane, L, W, T)
        end
    elseif shape == "Rod"
        if plane == "xz"
            #triangles have to be placed with face in the xz plane
            return circle_vertices(x1_coordinate_slider, x2_coordinate_slider, R) 
        else
            return rectangle_vertices(x1_coordinate_slider, x2_coordinate_slider, plane, L, W, T)
        end
    end
end

function set_plane(plane, L, W, T)
    if plane == "xz"
        return [W, L]
    elseif plane == "xy"
        return [W, T]
    elseif plane == "yz"
        return [T, L]
    end
end

function rectangle_vertices(x1_coordinate_slider, x2_coordinate_slider, plane, L, W, T)
    dim1, dim2 = set_plane(plane, L,W,T)
    vertices = lift(x1_coordinate_slider.value, x2_coordinate_slider.value) do x1, x2
        [
            Point2f(x1 + dim1, x2 + dim2),
            Point2f(x1 + dim1, x2 - dim2),
            Point2f(x1 - dim1, x2 - dim2),
            Point2f(x1 - dim1, x2 + dim2)
        ]
    end
    return vertices#z_domain = 400:0.01:600
end
    
function triangle_vertices(x1_coordinate_slider, x2_coordinate_slider, W, L)
    vertices = lift(x1_coordinate_slider.value, x2_coordinate_slider.value) do x1, x2
        [
            Point2f(x1, x2 + L),
            Point2f(x1 + W, x2 - L),
            Point2f(x1 - W, x2 - L)
        ]
    end
    return vertices
end

function circle_vertices(x1_coordinate_slider, x2_coordinate_slider, R) 
        vertices = lift(x1_coordinate_slider.value, x2_coordinate_slider.value) do x1, x2
            Circle(Point2f(x1, x2), R)
        end
    return vertices
end

function place_shape(x1_coordinate_slider, x2_coordinate_slider, plane, L, W, T, R, shape)
    center_coordinates = lift(x1_coordinate_slider.value, x2_coordinate_slider.value) do x1, x2
        Point2f(x1, x2)
    end
    vertice_coordinates = get_vertices(x1_coordinate_slider, x2_coordinate_slider, plane, L, W, T, R, shape)
    x1_coordinate_string = lift(x1 -> "$x1", x1_coordinate_slider.value)
    x2_coordinate_string = lift(x2 -> "$x2", x2_coordinate_slider.value)
    return [center_coordinates, vertice_coordinates, x1_coordinate_string, x2_coordinate_string]
end


        

geometry, config = load_JSON()
config = config[1]
x_domain = 0:0.01:config["x_span"]
z_domain = 0:0.01:config["z_span"]
y_domain = 0:0.01:config["y_span"]
fig = Figure()
for k = 1:length(geometry)
    
    #pull shape parameters from the json file
    T = geometry[k]["thickness"] * config["scaling_factor"] #thickness, along Y
    L = geometry[k]["length"] * config["scaling_factor"]    #length, along Z
    W = geometry[k]["width"] * config["scaling_factor"]     #width, along x
    R = geometry[k]["radius"] * config["scaling_factor"]
    #set initial positions
    x0, y0, z0 = geometry[k]["position"]
    
    #setup each slider below the main figure windows
    x_slider = Slider(fig[0, 1], range = x_domain, startvalue = x0)
    y_slider = Slider(fig[0, 1], range = y_domain, startvalue = y0)
    z_slider = Slider(fig[0, 1], range = z_domain, startvalue = z0)

    #pull data from the sliders to update shape positions in the figures
    xy_center_coordinates, xy_vertice_coordinates, X_coordinate_string, Y_coordinate_string = place_shape(x_slider, y_slider, "xy", L/2, W/2, T/2, R, geometry[k]["shape"])
    xz_center_coordinates, xz_vertice_coordinates, _, Z_coordinate_string = place_shape(x_slider, z_slider, "xz", L/2, W/2, T/2, R, geometry[k]["shape"])
    yz_center_coordinates, yz_vertice_coordinates, _, _ = place_shape(y_slider, z_slider, "yz", L/2, W/2, T/2, R, geometry[k]["shape"])
    
    #set the color of the shape based on the material, for now only air gets a different color
    c = (:red, 0.5)
    if geometry[k]["material"] == "air"
        c = (:skyblue, 0.5)
    elseif geometry[k]["material"] == "gold"
        c = (:gold, 0.5)
    elseif geometry[k]["material"] == "chromium"
        c = (:gray, 0.5)
    elseif geometry[k]["material"] == "201"
    	c = (:blue, 0.5)
    end
    #define Axis for XY window with aspect ratio defined by domain size
    ax1 = Axis(fig[1, 1], xlabel = "X Slider", title = "XY - Plane", aspect = x_domain[end] / y_domain[end])
    
    #place the polygon for the current shape in the XY window
    poly!(xy_vertice_coordinates, color = c)
    
    #mark the center point for the current shape in the XY window
    scatter!(xy_center_coordinates)
    #set window axis limis
    limits!(ax1, 1, x_domain[end], 1, y_domain[end])
    
    #define Axis for XZ window with aspect ratio defined by domain size
    #ax2 = Axis(fig[1, 2], xlabel = "Y Slider", title = "XZ - Plane", aspect = x_domain[end] / z_domain[end])
    ax2 = Axis(fig[1, 2], xlabel = "Y Slider", title = "XZ - Plane")
    #place the polygon for the current shape in the XZ window
    poly!(xz_vertice_coordinates, color = c)
    #mark the center point for the current shape in the XZ window
    scatter!(xz_center_coordinates)
    #place axis labels for reading coordinates
    #text!("x", color = :black, position = (50,30 * (length(geometry)+1)))
    #text!("y", color = :black, position = (130,30 * (length(geometry)+1)))
    #text!("z", color = :black, position = (210,30 * (length(geometry)+1)))
    #place coordinate values for current shape
    #text!(X_coordinate_string, color = :black, position = (50,30 * k))
    #text!(Y_coordinate_string, color = :black, position = (130,30 * k))
    #text!(Z_coordinate_string, color = :black, position = (210,30 * k))
    #place label for current shape
    #text!(string("G",k), color = :black, position = (10,30 * k))
    #set window axis limis
    limits!(ax2, 1, x_domain[end], 1, z_domain[end])

    #define Axis for YZ window with aspect ratio defined by domain size
    ax3 = Axis(fig[1, 3], xlabel = "Z Slider", title = "YZ - Plane", aspect = y_domain[end] / z_domain[end])
    #place the polygon for the current shape in the YZ window
    poly!(yz_vertice_coordinates, color = c)
    #mark the center point for the current shape in the YZ window
    scatter!(yz_center_coordinates)
    #set window axis limis
    limits!(ax3, 1, y_domain[end], 1, z_domain[end])


end 

fig
wait(display(fig))
