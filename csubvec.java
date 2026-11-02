// csubvec.java -- Keith's csub.java kernel written with the JDK Vector API
// (jdk.incubator.vector, JDK 17+) : explicit SIMD, float32 (2026 variant).
// Element loop in SIMD lanes: each lane still computes in + ix + iy for its
// own ix. Requires: javac/java --add-modules jdk.incubator.vector.
import jdk.incubator.vector.*;

public class csubvec {
   static final VectorSpecies<Float> S = FloatVector.SPECIES_PREFERRED;
   static final FloatVector IOTA = FloatVector.zero(S).addIndex(1);   // 0,1,2,... as floats

   public static void subr(float in[][],int nx,int ny,float out[][]) {
      int bound = S.loopBound(nx);
      for (int iy = 0; iy < ny; iy++) {
         float[] rin = in[iy], rout = out[iy];
         int ix = 0;
         for (; ix < bound; ix += S.length()) {
            FloatVector v = FloatVector.fromArray(S, rin, ix);
            v.add(IOTA.add((float)(ix + iy))).intoArray(rout, ix);
         }
         for (; ix < nx; ix++) rout[ix] = rin[ix] + iy + ix;
      }
   }
   public static void main(String[] args) {
      int ny = 10, nx = 2000, nrpt = 1000;
      if (args.length > 0) nrpt = Integer.parseInt(args[0]);
      if (args.length > 1) nx = Integer.parseInt(args[1]);
      if (args.length > 2) ny = Integer.parseInt(args[2]);
      float in[][] = new float[ny][nx];
      float out[][] = new float[ny][nx];
      for (int iy = 0; iy < ny; iy++)
         for (int ix = 0; ix < nx; ix++) in[iy][ix] = (nx - ix + ny - iy);
      System.out.println("Arrays have " + ny + " rows of " + nx + " columns, repeats = " + nrpt + " lanes " + S.length());
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
