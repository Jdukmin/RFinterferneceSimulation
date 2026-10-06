from refine_geometry import main
import refine_geometry as refine
refine.CANDIDATES = [(130,93,6,45,12,1.5),(130,92,6,45,12,1.5),(130,94,6,45,12,2.5),(130,93,6,45,12,2.5),(130,92,6,45,12,3)]
original_screen = refine.screen
refine.screen = lambda index, values: original_screen(index + 8, values)
if __name__ == '__main__':
    main()
