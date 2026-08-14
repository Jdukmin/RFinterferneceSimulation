classdef SpectrumModel
    %SPECTRUMMODEL Abstract TX spectrum (ICD spectrum.md 3). PSD is absolute and
    %   LINEAR (W/Hz); total power is dBm. Integration happens in linear units
    %   only (SR-211). Concrete subclasses: RectangularSpectrum, TabulatedSpectrum.
    properties (SetAccess = protected)
        provenance      % SpectrumProvenance char
        referencePlane  % receiver.ReferencePlane char (default TX_ANTENNA_INPUT)
        psdKind         % 'ABSOLUTE_PSD'
    end
    methods
        function y = psd_WPerHz(obj, f_Hz) %#ok<STOUT,INUSD>
            error('rfscreen:spectrum:abstract', 'psd_WPerHz must be implemented by a subclass.');
        end
        function b = supportBand_Hz(obj) %#ok<STOUT,MANU>
            error('rfscreen:spectrum:abstract', 'supportBand_Hz must be implemented by a subclass.');
        end
        function g = nativeGrid_Hz(obj) %#ok<STOUT,MANU>
            error('rfscreen:spectrum:abstract', 'nativeGrid_Hz must be implemented by a subclass.');
        end
        function p = totalPower_dBm(obj) %#ok<STOUT,MANU>
            error('rfscreen:spectrum:abstract', 'totalPower_dBm must be implemented by a subclass.');
        end
        function w = totalPower_W(obj)
            w = rfscreen.util.Units.dbm2w(obj.totalPower_dBm());
        end
        function b = occupiedBandwidth_Hz(obj) %#ok<STOUT,MANU>
            error('rfscreen:spectrum:abstract', 'occupiedBandwidth_Hz must be implemented by a subclass.');
        end
        function f = fc_Hz(obj) %#ok<STOUT,MANU>
            error('rfscreen:spectrum:abstract', 'fc_Hz must be implemented by a subclass.');
        end
    end
end
