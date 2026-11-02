// csubd.java -- Keith's csub.java with double (64-bit) arrays (2026 variant).
// Identical loop; only the element type changes, so it can be compared
// like-for-like with the Kotlin, Clojure, C# and F# entries, which use double.
public class csubd {
   public static void subr(double in[][],int nx,int ny,double out[][]) {
      for (int iy = 0; iy < ny; iy++) {
         for (int ix = 0; ix < nx; ix++) {
            out[iy][ix] = in[iy][ix] + iy + ix;
         }
      }
   }
   public static void main(String[] args) {
      int ny = 10, nx = 2000, nrpt = 1000;
      if (args.length > 0) nrpt = Integer.parseInt(args[0]);
      if (args.length > 1) nx = Integer.parseInt(args[1]);
      if (args.length > 2) ny = Integer.parseInt(args[2]);
      double in[][] = new double[ny][nx];
      double out[][] = new double[ny][nx];
      for (int iy = 0; iy < ny; iy++)
         for (int ix = 0; ix < nx; ix++) in[iy][ix] = (nx - ix + ny - iy);
      System.out.println("Arrays have " + ny + " rows of " + nx + " columns, repeats = " + nrpt);
      for (int irpt = 0; irpt < nrpt; irpt++) subr(in,nx,ny,out);
      testloop:
      for (int iy = 0; iy < ny; iy++)
         for (int ix = 0; ix < nx; ix++)
            if (out[iy][ix] != in[iy][ix] + (ix + iy)) {
               System.out.println("Error " + out[iy][ix] + " " + ix + " " + iy);
               break testloop;
            }
   }
}
