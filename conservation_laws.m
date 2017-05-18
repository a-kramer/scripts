function conservation_laws(Model,varargin)
## Usage: conservation_laws(Model,['test'])
##
## Model.flux(x,t,p): reaction fluxes, needed for testing, with lsode
## Model.f(flux): function that converts fluxes to ODE right-hand-side
## Model.x_names: names of state variables
## Model.ns: number of state variables
## Model.nr: number of reactions
## Model.np: number of parameters

## get stoichiometry from fluxes
N=get_stoichiometry(Model);
n=get_laws(N,Model.x_names);
if (nargin>1 && strcmp(varargin{1},'test'))
 p=rand(Model.np,1);
 x0=rand(Model.ns,1);
 t=linspace(0,1,64);
 ode=@(x,t) Model.f(Model.flux(x,t,p));
 X=lsode(ode,x0,t);
 show_conservation(t,X,Model.x_names,n);
endif

endfunction

function n_rref=get_laws(N,substances)
# given a cell array of substance names and stoichimetric matrix N
# this function finds conservation laws in the reaction system
# Usage:
#         C=conservation_laws(N,substances)
# C is a matrix of coefficients, the columns span the space of conservation laws
# Example: given state variables X(1:3) and C=[1;1;2], then X(1) + X(2) + 2*X(3) = cons.

n=null(N');
n_rref=rref(n')';
if (norm(n_rref-round(n_rref)) < 1e-6)
 n_rref=round(n_rref);
else
 warning("nullspace is not represented by integers.\
        \nTo make the mass conservation more readable, we multiply them by 100 and round.\
        \nThe output can be interpreted as given in percentages.");
 n_rref=round(100*n_rref);
endif

c=columns(n_rref);
Y=cell(c,2);
s='+-';
for i=c:-1:1
 Y{i,1}=[sign(n_rref(:,i))>0];
 Y{i,2}=[sign(n_rref(:,i))<0];
 for j=1:2
  I=find(Y{i,j});
  for k=1:length(I)
   printf("%s %s%s ",merge(j==1 && k==1,'',s(j)),...
                      merge(abs(n_rref(I(k),i))>1,sprintf("%i·",abs(n_rref(I(k),i))),''),...
                      substances{I(k)});
  endfor
 endfor
 printf("= const.\n"); 
endfor
printf("the constants can be determined from the initial conditions of the system.\n");
endfunction

function N=get_stoichiometry(M)
#
# Usage N=get_stoichiometry(M)
#
#  M: ode model structure. contains
#     M.ns number of substances
#     M.nr number of reactions
#     M.f(flux) ODE right hand side function; the vector field of fluxes, 
#               the flux is a column vector which contains every reaction's flux 
#                                              (derived from the reaction kinetic)
#               This is only needed to check which flux influences which state variable.
N=zeros(M.ns,M.nr);
r=M.nr;
for j=1:r
 N(:,j)=sign(M.f([1:r]==j));
endfor
endfunction

function show_conservation(t,X,substances,n)
##
## Usage: show_conservation_law(X,substances,n)
##
##  X, lsode output, the solution of the initial value problem. Each
##  state variable is represented by a column; the row index
##  corresponds to the time index.
##
##  substances is a cell array of strings with substance names.
##
## n represents the conservation law, is returned by the function:
## n=conservation_laws(N,substances)
##
  nt=length(t);
  s='+-';
  
  for i=columns(n):-1:1
    T="";
    Y{i,1}=[sign(n(:,i))>0];
    Y{i,2}=[sign(n(:,i))<0];
    for j=1:2
      I=find(Y{i,j});
      for k=1:length(I)
	T=cat(2,T,sprintf("%s %s%s ",merge(j==1 && k==1,'',s(j)),...
		  merge(abs(n(I(k),i))>1,sprintf("%i·",abs(n(I(k),i))),''),...
		  substances{I(k)}));
      endfor
    endfor
    Z=X*n(:,i);
    figure(); clf;
    plot(t,Z,sprintf("-;conservation law %i;",i));
    title(T,"interpreter","none");
    xlabel("t");
    ylabel("concentration");
  endfor
  figure(); clf;
  plot(t,X,";;");
  title("model trajectories");
  xlabel("t");
  ylabel("X_i");
  legend(substances{:},"location","southoutside");
endfunction
