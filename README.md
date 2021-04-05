# terrain
A terrain generation sandbox in Godot. It requires a custom module with bindings 
to the [robust](https://github.com/danshapero/predicates) C++ library, this a zip file of this module will later be uploaded.

## State
I am somewhat actively working on this project for fun when I have the time, there are no guarantees
whatsoever in regard to the functioning of this code. Some height genereration logic using 
spherical random walks has been implemented but is currently not being used. 

## Goal
The aim is to create a program that models various biomes on a planet in a mostly realistic fashion.
The terrain genereration should supersede simple fractal models (such as diamond-square, fractal noise),
used often for terrain generation that aren't suited for the 
modelling of entire planets with diverse biomes. Therefore, the aim of the project is to create realistic 
macro structure (oceans, mountainous areas, plateus) along the spherical planet which is subdivided
into a certain amount of mostly evenly distributed, triangular faces between randomly samples vertices.
