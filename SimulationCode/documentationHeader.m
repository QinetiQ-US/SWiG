%> @file  documentationHeader.m
%> @brief Documentation Header for SWiG Protocol Simulation Tools
%======================================================================
%> @mainpage SWiG Protocol Simulation Tools
%>
%> @section intro Introduction
%>
%> Provides tools for flexibly simulating undersea acoustic networks 
%> based on the in-progress proposal for standard for SWiG
%>
%>
%> @section classes Important Classes
%> Classes employed at the user application level:<br>
%> modulatorClass - abstract class encapsulating modulator behaviors<br>
%> packetClass - class encapsulating behaviors of packets<br>
%> nodeClass - class encapsulating behavior of a node<br>
%> Other classes are defined to help implement these. Other classes (in
%> particular specific modulators) inherit from these classes.
%> @section samples Sample Scripts
%> Several scripts are provided as practical examples for configuring and
%> running network simulations.<br>
%> runTestStoreAndForward.m - a sample script showing how to configure and
%> run various store-and-forward networks. Utilizes parfor to parallelize
%> running multiple simulations at once. Strongly suggested that this be
%> run on a workstation with at least 12 physical cores - otherwise change
%> "parfor" to "for"<br>
%> runTestMesh.m - sample script showing how to configure and run multiple
%>mesh network configurations. Due to oddities of Matlab, this cannot
%>readily be parallelized<br>
%>runSMACHDtest.m - sample script showing how to configure and run multiple
%> simulations of HD scheduling and use. This is parallelized, and can be
%> run on a computer with 4 or more cores without changing the "parfor"
%> construct.
